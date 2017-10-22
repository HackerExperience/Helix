import Helix.Process

process Helix.Software.Process.Cracker.Overflow do
  @moduledoc false

  alias Helix.Network.Model.Connection
  alias Helix.Process.Model.Process
  alias Helix.Software.Model.File

  @type creation_params ::
    %{
      target_process_id: Process.idtb | nil,
      target_connection_id: Connection.idtb | nil
    }

  process_struct [:target_process_id, :target_connection_id]

  @process_type :cracker_overflow

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

  def objective(params = %{cracker: %File{}}),
    do: set_objective params

  process_type do

    alias Helix.Network.Model.Connection
    alias Helix.Process.Model.Process
    alias Helix.Software.Process.Cracker.Overflow, as: OverflowProcess

    alias Helix.Software.Event.Cracker.Overflow.Processed,
      as: OverflowProcessedEvent

    def dynamic_resources(_),
      do: [:cpu]

    def minimum(_) do
      %{
        paused: %{ram: 24},
        running: %{ram: 24}
      }
    end

    on_completion(data) do
      event = OverflowProcessedEvent.new(process, data)

      {:ok, [event]}
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

  process_objective do

    alias Helix.Software.Factor.File, as: FileFactor

    @type params :: term
    @type factors :: term

    get_factors(%{cracker: cracker}) do
      factor FileFactor, %{file: cracker},
        only: :version,
        as: :cracker
    end

    # TODO: Testing and proper balance
    cpu do
      f.cracker.version.overflow
    end
  end

  executable do

    @process Helix.Software.Process.Cracker.Overflow

    objective(_, _, _, %{cracker: cracker}) do
      %{cracker: cracker}
    end

    file(_gateway, _target, _params, %{cracker: cracker}) do
      cracker.file_id
    end

    connection(_, _, _, _) do
      # TODO
      :ok
    end

  end

  process_viewable do

    @type data :: %{}

    render_empty_data()
  end
end
