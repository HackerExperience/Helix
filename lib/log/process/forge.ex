import Helix.Process

process Helix.Log.Process.Forge do
  @moduledoc """
  `LogForgeProcess` is launched when the user wants to edit an existing log, or
  create a new one from scratch.
  """

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
      ssh: Connection.t | nil
    }

  @type resources_params ::
    %{
      action: action,
      log: Log.t | nil,
      forger: File.t_of_type(:log_forger)
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
    %{action: action, forger: forger = %File{type: :log_forger}}
  ) do
    %__MODULE__{
      log_type: log_type,
      log_data: log_data,
      forger_version: get_forger_version(forger, action)
    }
  end

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

    alias HELL.MapUtils
    alias Helix.Log.Event.Forge.Processed, as: LogForgeProcessedEvent

    on_completion(process, data) do
      event = LogForgeProcessedEvent.new(process, data)

      {:delete, [event]}
    end

    @doc false
    def after_read_hook(data) do
      %LogForgeProcess{
        log_type: String.to_existing_atom(data.log_type),
        log_data: MapUtils.atomize_keys(data.log_data),
        forger_version: data.forger_version
      }
    end
  end

  resourceable do

    @type params :: LogForgeProcess.resources_params
    @type factors ::
      %{
        :forger => %{version: FileFactor.fact_version},
        optional(:log) => Log.t
      }

    get_factors(_) do

    end

    # get_factors(%{action: :edit, log: log, forger: forger}) do
    #   factor FileFactor, %{file: forger},
    #     only: [:version], as: :forger
    #   factor LogFactor, %{log: log},
    #     only: [:total_revisions]
    # end

    # get_factors(%{action: :create, forger: forger}) do
    #   factor FileFactor, %{file: forger},
    #     only: [:version], as: :forger
    # end

    # TODO: time resource (for minimum duration)

    cpu(%{action: :edit}) do
      f.forger.version.log_edit * f.log.revisions.total
    end

    cpu(%{action: :create}) do
      f.forger.version.log_create
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

    resources(_gateway, _target, _params, meta) do
      %{
        log: meta.log,
        forger: meta.forger,
        action: meta.action
      }
    end

    source_file(_gateway, _target, _params, %{forger: forger}) do
      forger.file_id
    end

    source_connection(_gateway, _target, _params, %{ssh: ssh}) do
      ssh.connection_id
    end

    target_log(_gateway, _target, _params, %{action: :edit, log: log}) do
      log.log_id
    end
  end
end
