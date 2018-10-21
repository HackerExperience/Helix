import Helix.Process

process Helix.Software.Process.Cracker.Overflow do
  @moduledoc false

  alias Helix.Software.Model.File

  process_struct []

  @type t :: %__MODULE__{}

  @type creation_params :: %{}

  @type executable_meta ::
    %{
      cracker: File.t
    }

  @type objective :: %{cpu: resource_usage}

  @type resources ::
    %{
      objective: objective,
      static: map,
      l_dynamic: [:cpu],
      r_dynamic: []
    }

  @type resources_params ::
    %{
      cracker: File.t
    }

  @process_type :cracker_overflow

  @spec new(creation_params, executable_meta) ::
    t
  def new(_, _),
    do: %__MODULE__{}

  @spec resources(resources_params) ::
    resources
  def resources(params = %{cracker: %File{}}),
    do: get_resources params

  processable do

    alias Helix.Software.Process.Cracker.Overflow, as: OverflowProcess

    alias Helix.Software.Event.Cracker.Overflow.Processed,
      as: OverflowProcessedEvent

    on_completion(process, data) do
      event = OverflowProcessedEvent.new(process, data)

      {:delete, [event]}
    end
  end

  resourceable do

    alias Helix.Software.Factor.File, as: FileFactor
    alias Helix.Software.Model.File
    alias Helix.Software.Process.Cracker.Overflow, as: OverflowProcess

    @type params :: OverflowProcess.resources_params
    @type factors ::
      %{
        cracker: %{version: FileFactor.fact_version}
      }

    get_factors(%{cracker: cracker}) do
      factor FileFactor, %{file: cracker},
        only: :version,
        as: :cracker
    end

    # TODO: Testing and proper balance
    cpu do
      f.cracker.version.overflow
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

    @type custom :: %{}

    resources(_, _, _, %{cracker: cracker}, _) do
      %{cracker: cracker}
    end

    source_file(_gateway, _target, _params, %{cracker: cracker}, _) do
      cracker.file_id
    end

    source_connection(_, _, _, %{ssh: ssh}, _) do
      ssh.connection_id
    end

    target_connection(_, _, _, %{connection: connection}, _) do
      connection.connection_id
    end

    target_process(_, _, _, %{process: process}, _) do
      process.process_id
    end
  end

  process_viewable do

    @type data :: %{}

    render_empty_data()
  end
end
