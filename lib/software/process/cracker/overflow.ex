import Helix.Process

process Helix.Software.Process.Cracker.Overflow do
  @moduledoc false

  alias Helix.Software.Model.File

  process_struct []

  @type t :: %__MODULE__{}

  @type creation_params :: %{}

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

  @spec new(creation_params) ::
    t
  def new(_),
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

    alias Helix.Software.Model.File
    alias Helix.Software.Process.Cracker.Overflow, as: OverflowProcess

    @type params :: OverflowProcess.creation_params
    @type meta ::
      %{
        :cracker => File.t,
        optional(atom) => term
      }

    resources(_, _, _, %{cracker: cracker}) do
      %{cracker: cracker}
    end

    source_file(_gateway, _target, _params, %{cracker: cracker}) do
      cracker.file_id
    end

    source_connection(_, _, _, %{ssh: ssh}) do
      ssh.connection_id
    end

    target_connection(_, _, _, %{connection: connection}) do
      connection.connection_id
    end

    target_process(_, _, _, %{process: process}) do
      process.process_id
    end
  end

  process_viewable do

    @type data :: %{}

    render_empty_data()
  end
end
