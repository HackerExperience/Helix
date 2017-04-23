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

    def conclusion(data, process) do
      process =
        process
        |> Ecto.Changeset.change()
        |> Map.put(:action, :delete)

      events = event(data, process, :completed)

      {process, events}
    end

    def event(data, process, :completed) do
      event = %ProcessConclusionEvent{
        to_server_id: process.gateway_id,
        from_server_id: process.target_server_id,
        from_file_id: data.target_file_id,
        to_storage_id: data.destination_storage_id,
        network_id: process.network_id
      }

      [event]
    end

    def event(_, _, _) do
      []
    end
  end
end
