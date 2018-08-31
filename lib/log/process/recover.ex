import Helix.Process

process Helix.Log.Process.Recover do
  @moduledoc """
  `LogRecoverProcess` is launched when the user wants to recover one or more
  logs. Recovery may happen in two ways: `global` or `custom`.

  - Global: This recovery method acts like a scanner. The LogRecoverProcess will
    scan the server's logs for any log that may have revisions, and then work on
    whichever log it chose.

  - Custom: This recovery method is a little bit more direct. The player chooses
    a log and then the LogRecoverProcess will work on that log.

  In both methods, the process will run in a recursive fashion: once a revision
  is found, it will send a `SIG_RETARGET` and the process will find a new target.
  `global` processes might choose a different log to recover, while `custom`
  processes will keep working on the same log.

  The `custom` method is a bit faster than `global`, but it may work on a log
  that has no revisions. It also uses more CPU than `global`.

  If `custom` is executing on a log that is already on its original revision,
  the process will keep working infinitely. The user does not know whether the
  target log is on its final revision or not.

  If `global` is working on a server that have all its logs on their original
  revision, it will keep working infinitely. The user does not know whether the
  target log is on its final revision or not.
  """

  alias Helix.Entity.Model.Entity
  alias Helix.Network.Model.Connection
  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.File
  alias Helix.Log.Model.Log
  alias Helix.Log.Query.Log, as: LogQuery
  alias __MODULE__, as: LogRecoverProcess

  process_struct [:recover_version]

  @type t ::
    %__MODULE__{
      recover_version: pos_integer
    }

  @type method :: :global | :custom
  @type process_type :: :log_recover_global | :log_recover_custom

  @type creation_params :: %{}

  @type executable_meta ::
    %{
      recover: File.t_of_type(:log_recover),
      method: LogRecoverProcess.method,
      log: Log.t | nil,
      ssh: Connection.t | nil,
      network_id: Network.id | nil,
      entity_id: Entity.id
    }

  @type resources_params ::
    %{
      method: method,
      log: Log.t | nil,
      recover: File.t_of_type(:log_recover) | nil,
      recover_version: pos_integer | nil,
      entity_id: Entity.id
    }

  @type resources ::
    %{
      objective: objective,
      static: map,
      l_dynamic: [:cpu],
      r_dynamic: []
    }

  @type objective :: %{cpu: resource_usage}

  @spec new(creation_params, executable_meta) ::
    t
  def new(%{}, %{recover: recover = %File{software_type: :log_recover}}) do
    %__MODULE__{
      recover_version: recover.modules.log_recover.version
    }
  end

  @spec get_process_type(creation_params, executable_meta) ::
    process_type
  def get_process_type(_, %{method: :global}),
    do: :log_recover_global
  def get_process_type(_, %{method: :custom}),
    do: :log_recover_custom

  @spec resources(resources_params) ::
    resources
  def resources(params),
    do: get_resources params

  @spec find_next_target(Server.idt) ::
    Log.t
    | nil
  @doc """
  Selects the next log that we should work on. Only called on `global` method.

  IMPROVE: If there are other recover process from attacker at server, make sure
  to select a different log, allowing users to run multiple "threads" of the
  LogRecoverProcess.
  """
  def find_next_target(server) do
    recoverable_logs =
      server
      |> LogQuery.get_logs_on_server()
      |> Enum.filter(&(Log.count_extra_revisions(&1) >= 1))

    if Enum.empty?(recoverable_logs) do
      nil
    else
      Enum.random(recoverable_logs)
    end
  end

  processable do

    alias Helix.Log.Event.Recover.Processed, as: LogRecoverProcessedEvent

    on_completion(process, data) do
      event = LogRecoverProcessedEvent.new(process, data)

      # We can't send a SIG_RETARGET now because if we do so, it might fetch the
      # existing Log before the freshly recovered revision isn't removed from it
      # yet. So, to fix this race condition, we first process the log recovery
      # (by handling `LogRecoverProcessedEvent`), and only then we send the
      # SIG_RETARGET to this process.
      {:noop, [event]}
    end

    @doc """
    When a `:retarget` is requested, we'll find a new target for the process. If
    it's a `Global` process, a random log is selected on each iteration. If it's
    a `Custom` process, however, the same log is always selected.
    """
    on_retarget(process, _data) do
      {new_log, method} =
        # On `log_recover_global`, we must select a new log on each iteration.
        if process.type == :log_recover_global do
          log = LogRecoverProcess.find_next_target(process.target_id)
          {log, :global}

        # On `log_recover_custom` we always work at the same log. May be `nil`.
        else
          log = LogQuery.fetch(process.tgt_log_id)
          {log, :custom}
        end

      params =
        %{
          method: method,
          log: new_log,
          recover: nil,
          recover_version: process.data.recover_version,
          entity_id: process.source_entity_id
        }

      new_resources = LogRecoverProcess.resources(params)
      new_objects = %{tgt_log_id: new_log && new_log.log_id || nil}

      changes = Map.merge(new_resources, new_objects)

      {{:retarget, changes}, []}
    end

    @doc """
    If the Log currently being recovered was recovered by someone else,
    automatically `:retarget` the process.
    """
    on_target_log_recovered(_process, _data, _log) do
      {:SIG_RETARGET, []}
    end

    @doc """
    If the Log currently being recovered was destroyed, `:retarget` if it's a
    global process, otherwise the custom process should be killed and the user
    notified.
    """
    on_target_log_destroyed(%{type: :log_recover_global}, _data, _log) do
      {:SIG_RETARGET, []}
    end

    on_target_log_destroyed(%{type: :log_recover_custom}, _data, _log) do
      {{:SIGKILL, :tgt_log_deleted}, []}
    end
  end

  resourceable do

    alias Helix.Software.Factor.File, as: FileFactor
    alias Helix.Log.Factor.Log, as: LogFactor

    @type params :: LogRecoverProcess.resources_params
    @type factors ::
      %{
        optional(:recover) => %{version: FileFactor.fact_version},
        :log => LogFactor.fact_revisions
      }

    get_factors(%{log: nil}) do
      %{log: nil}
    end

    get_factors(params) do
      factor FileFactor, %{file: params.recover},
        if: not is_nil(params.recover), only: :version, as: :recover
      factor LogFactor, %{log: params.log, entity_id: params.entity_id},
        only: :revisions, as: :log

      factors =
        if is_nil(params.recover) do
          Map.put(
            factors,
            :recover,
            %{version: %{log_recover: params.recover_version}}
          )
        else
          factors
        end
    end

    # TODO: time resource (for minimum duration) #364

    # `log` may be nil iff `method = :global`, when there are no logs that can
    # be recovered. This means infinite work!
    cpu(%{log: nil}) do
      999_999_999_999
    end

    cpu(%{method: method}) do
      multiplier =
        if method == :custom,
          do: 500,
          else: 1000

      if f.log.revisions.extra == 0 do
        999_999_999_999
      else
        t = (f.log.revisions.total * multiplier) / f.recover.version.log_recover

        t + 5000
      end
    end

    dynamic do
      [:cpu]
    end

    static do
      %{
        paused: %{ram: 100},
        running: %{ram: 200}
      }
    end
  end

  executable do

    import HELL.Macros

    @type custom :: %{log: Log.t | nil}

    custom(_, target, _params, meta) do
      log =
        # If it's a `global` recovery, we'll randomly select a recoverable log
        if meta.method == :global do
          LogRecoverProcess.find_next_target(target)

        # But if it's a `custom` recovery, the user already selected a log
        else
          meta.log
        end

      %{log: log}
    end

    resources(_gateway, _, _params, meta, custom) do
      log =
        if meta.method == :global do
          custom.log
        else
          meta.log
        end

      %{
        log: log,
        recover: meta.recover,
        method: meta.method,
        entity_id: meta.entity_id
      }
    end

    source_file(_gateway, _target, _params, %{recover: recover}, _) do
      recover.file_id
    end

    docp """
    The LogRecoverProcess have a `source_connection` when the player is
    recovering a log on a remote server.

    However, if the operation is local, there is no `source_connection`.
    """
    source_connection(_, _, _, %{ssh: ssh = %Connection{}}, _) do
      ssh
    end

    docp """
    `custom` log is nil => there are no recoverable logs on the server.
    """
    target_log(_gateway, _target, _params, %{method: :global}, %{log: nil}) do
      nil
    end

    docp """
    `custom` log is not nil => Random recoverable log was select, and that is
    the one we'll work on during this process iteration.
    """
    target_log(_gateway, _target, _params, %{method: :global}, %{log: log}) do
      log.log_id
    end

    docp """
    Method is `custom`, so the player already choose which log we'll work on.
    """
    target_log(_gateway, _target, _params, %{method: :custom, log: log}, _) do
      log.log_id
    end
  end

  process_viewable do

    @type data :: %{}

    render_empty_data()
  end
end
