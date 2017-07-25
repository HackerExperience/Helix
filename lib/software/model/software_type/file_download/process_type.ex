# FIXME: OTP20
defmodule Software.FileDownload.ProcessType do

  @enforce_keys [:target_file_id, :destination_storage_id]
  defstruct [:target_file_id, :destination_storage_id]

  defimpl Helix.Process.Model.Process.ProcessType do

    alias Helix.Software.Model.SoftwareType.FileDownload.ProcessConclusionEvent

    def dynamic_resources(_),
      do: [:dlk]

    def minimum(_),
      do: %{}

    def kill(_, process, _),
      do: {%{Ecto.Changeset.change(process)| action: :delete}, []}

    def state_change(data, process, _, :complete) do
      process =
        process
        |> Ecto.Changeset.change()
        |> Map.put(:action, :delete)

      event = %ProcessConclusionEvent{
        to_server_id: Ecto.Changeset.get_field(process, :gateway_id),
        from_server_id: Ecto.Changeset.get_field(process, :target_server_id),
        from_file_id: data.target_file_id,
        to_storage_id: data.destination_storage_id,
        network_id: Ecto.Changeset.get_field(process, :network_id)
      }

      {process, [event]}
    end

    def state_change(_, process, _, _),
      do: {process, []}

    def conclusion(data, process),
      do: state_change(data, process, :running, :complete)
  end

  defimpl Helix.Process.API.View.Process do

    alias Helix.Process.Model.Process
    alias Helix.Process.Model.Process.Resources
    alias Helix.Process.Model.Process.State

    @spec render(map, Process.t, HELL.PK.t, HELL.PK.t) ::
      %{
        :process_id => HELL.PK.t,
        :gateway_id => HELL.PK.t,
        :target_server_id => HELL.PK.t,
        :network_id => HELL.PK.t,
        :connection_id => HELL.PK.t,
        :process_type => term,
        :target_file_id => HELL.PK.t,
        optional(:state) => State.state,
        optional(:objective) => Resources.t,
        optional(:processed) => Resources.t,
        optional(:allocated) => Resources.t,
        optional(:priority) => 0..5,
        optional(:creation_time) => DateTime.t
      }
    def render(data, process = %{gateway_id: server}, server, _) do
      base = take_data_from_process(process)
      complement = %{
        target_file_id: data.target_file_id
      }

      Map.merge(base, complement)
    end

    def render(data, process, _, _) do
      base =
        process
        |> take_data_from_process()
        |> Map.drop([
          :state,
          :objective,
          :processed,
          :allocated,
          :priority,
          :creation_time
        ])

      complement = %{
        target_file_id: data.target_file_id
      }

      Map.merge(base, complement)
    end

    defp take_data_from_process(process) do
      %{
        process_id: process.process_id,
        gateway_id: process.gateway_id,
        target_server_id: process.target_server_id,
        network_id: process.network_id,
        connection_id: process.connection_id,
        process_type: process.process_type,
        state: process.state,
        objective: process.objective,
        processed: process.processed,
        allocated: process.allocated,
        priority: process.priority,
        creation_time: process.creation_time
      }
    end
  end
end
