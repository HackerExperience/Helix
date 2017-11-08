import Helix.Process

process Helix.Software.Process.Cracker.Overflow do
  @moduledoc false

  alias Helix.Network.Model.Connection
  alias Helix.Process.Model.Process
  alias Helix.Software.Model.File

  process_struct [:target_process_id, :target_connection_id]

  @type t ::
    %__MODULE__{
      target_process_id: Process.id | nil,
      target_connection_id: Connection.id | nil
    }

  @type creation_params ::
    %{
      target_process_id: Process.id | nil,
      target_connection_id: Connection.id | nil
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

  @spec new(creation_params) ::
    t
  def new(%{target_process_id: target_process_id}),
      do: new(target_process_id, nil)
  def new(%{target_connection_id: target_connection_id}),
    do: new(nil, target_connection_id)

  defp new(process_id, connection_id) do
    %__MODULE__{
      target_process_id: process_id,
      target_connection_id: connection_id
    }
  end

  @spec resources(resources_params) ::
    resources
  def resources(params = %{cracker: %File{}}),
    do: get_resources params

  processable do

    alias Helix.Network.Model.Connection
    alias Helix.Process.Model.Process
    alias Helix.Software.Process.Cracker.Overflow, as: OverflowProcess

    alias Helix.Software.Event.Cracker.Overflow.Processed,
      as: OverflowProcessedEvent

    on_completion(process, data) do
      event = OverflowProcessedEvent.new(process, data)

      {:delete, [event]}
    end

    def after_read_hook(data = %{target_connection_id: nil}),
      do: after_read_hook(Process.ID.cast!(data.target_process_id), nil)
    def after_read_hook(data = %{target_process_id: nil}),
      do: after_read_hook(nil, Connection.ID.cast!(data.target_connection_id))

    defp after_read_hook(target_process_id, target_connection_id) do
      %OverflowProcess{
        target_process_id: target_process_id,
        target_connection_id: target_connection_id
      }
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

    file(_gateway, _target, _params, %{cracker: cracker}) do
      cracker.file_id
    end

    connection(_, _, _, _) do
      # TODO
      nil
    end
  end

  process_viewable do

    @type data :: %{}

    render_empty_data()
  end
end
