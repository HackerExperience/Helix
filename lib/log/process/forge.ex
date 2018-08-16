import Helix.Process

process Helix.Log.Process.Forge do
  @moduledoc """
  `LogForgeProcess` is launched when the user wants to edit an existing log, or
  create a new one from scratch.
  """

  alias Helix.Entity.Model.Entity
  alias Helix.Network.Model.Connection
  alias Helix.Network.Model.Network
  alias Helix.Software.Model.File
  alias Helix.Log.Model.Log
  alias __MODULE__, as: LogForgeProcess

  process_struct [:log_type, :log_data, :forger_version]

  @type t ::
    %__MODULE__{
      log_type: Log.type,
      log_data: Log.data,
      forger_version: pos_integer
    }

  @type action :: :create | :edit
  @type process_type :: :log_forge_create | :log_forge_edit

  @type creation_params :: %{log_info: Log.info}

  @type executable_meta ::
    %{
      forger: File.t_of_type(:log_forger),
      action: LogForgeProcess.action,
      log: Log.t | nil,
      ssh: Connection.t | nil,
      network_id: Network.id | nil,
      entity_id: Entity.id | nil
    }

  @type resources_params ::
    %{
      action: action,
      log: Log.t | nil,
      forger: File.t_of_type(:log_forger),
      entity_id: Entity.id | nil
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
  def new(
    %{log_info: {log_type, log_data}},
    %{action: action, forger: forger = %File{software_type: :log_forger}}
  ) do
    %__MODULE__{
      log_type: log_type,
      log_data: log_data,
      forger_version: get_forger_version(forger, action)
    }
  end

  @spec get_process_type(creation_params, executable_meta) ::
    process_type
  def get_process_type(_, %{action: :create}),
    do: :log_forge_create
  def get_process_type(_, %{action: :edit}),
    do: :log_forge_edit

  @spec resources(resources_params) ::
    resources
  def resources(params),
    do: get_resources params

  @spec get_forger_version(File.t, action) ::
    pos_integer
  defp get_forger_version(forger = %File{}, :create),
    do: forger.modules.log_create.version
  defp get_forger_version(forger = %File{}, :edit),
    do: forger.modules.log_edit.version

  processable do

    alias Helix.Log.Model.LogType

    alias Helix.Log.Event.Forge.Processed, as: LogForgeProcessedEvent

    on_completion(process, data) do
      event = LogForgeProcessedEvent.new(process, data)

      {:delete, [event]}
    end

    @doc false
    def after_read_hook(data) do
      log_type = String.to_existing_atom(data.log_type)

      %LogForgeProcess{
        log_type: log_type,
        log_data: LogType.parse(log_type, data.log_data) |> elem(1),
        forger_version: data.forger_version
      }
    end
  end

  resourceable do

    alias Helix.Software.Factor.File, as: FileFactor
    alias Helix.Log.Factor.Log, as: LogFactor

    @type params :: LogForgeProcess.resources_params
    @type factors ::
      %{
        :forger => %{version: FileFactor.fact_version},
        optional(:log) => LogFactor.fact_revisions
      }

    get_factors(params) do
      factor FileFactor, %{file: params.forger},
        only: :version, as: :forger
      factor LogFactor, %{log: params.log, entity_id: params.entity_id},
        if: params.action == :edit, only: :revisions, as: :log
    end

    # TODO: time resource (for minimum duration) #364

    cpu(%{action: :edit}) do
      f.forger.version.log_edit * (1 + f.log.revisions.from_entity) + 5000
    end

    cpu(%{action: :create}) do
      f.forger.version.log_create + 5000
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

    @type custom :: %{}

    resources(_gateway, _target, _params, meta, _) do
      %{
        log: meta.log,
        forger: meta.forger,
        action: meta.action,
        entity_id: meta.entity_id
      }
    end

    source_file(_gateway, _target, _params, %{forger: forger}, _) do
      forger.file_id
    end

    docp """
    The LogForgeProcess have a `source_connection` when the player is forging a
    log on a remote server.

    However, if the operation is local, there is no `source_connection`.
    """
    source_connection(_, _, _, %{ssh: ssh = %Connection{}}, _) do
      ssh
    end

    docp """
    When editing an existing log, we have a valid `target_log` entry.

    If, however, we are creating a new log, there is no such entry, as the
    soon-to-be-created log does not exist yet!
    """
    target_log(_gateway, _target, _params, %{action: :edit, log: log}, _) do
      log.log_id
    end
  end

  process_viewable do

    @type data :: %{}

    render_empty_data()
  end
end
