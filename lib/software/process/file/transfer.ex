defmodule Helix.Software.Process.File.Transfer do

  alias Helix.Software.Model.Storage

  @type t :: %{
    type: :download | :upload,
    destination_storage_id: Storage.id,
    connection_type: :ftp | :public_ftp
  }

  @enforce_keys [:type, :destination_storage_id, :connection_type]
  defstruct [:type, :destination_storage_id, :connection_type]

  def objective(:download, file),
    do: %{dlk: file.file_size}
  def objective(:upload, file),
    do: %{ulk: file.file_size}

  defimpl Helix.Process.Model.Process.ProcessType do

    import Helix.Process.Model.Macros

    alias Helix.Software.Event.File.Transfer.Processed,
      as: FileTransferProcessedEvent

    def dynamic_resources(%{type: :download}),
      do: [:dlk]
    def dynamic_resources(%{type: :upload}),
      do: [:ulk]

    def minimum(_),
      do: %{}

    def kill(_, process, _) do
      {delete(process), []}
    end

    def state_change(data = %{type: :download}, process, _, :complete) do
      process = unchange(process)

      from_server_id = process.target_server_id
      to_server_id = process.gateway_id

      process_completion(from_server_id, to_server_id, data, process)
    end

    def state_change(data = %{type: :upload}, process, _, :complete) do
      process = unchange(process)

      from_server_id = process.gateway_id
      to_server_id = process.target_server_id

      process_completion(from_server_id, to_server_id, data, process)
    end

    def state_change(_, process, _, _),
      do: {process, []}

    defp process_completion(from_server_id, to_server_id, data, process) do
      event = %FileTransferProcessedEvent{
        entity_id: process.source_entity_id,
        to_server_id: to_server_id,
        from_server_id: from_server_id,
        file_id: process.file_id,
        network_id: process.network_id,
        to_storage_id: data.destination_storage_id,
        connection_type: data.connection_type,
        type: data.type
      }

      {delete(process), [event]}
    end

    def conclusion(data, process),
      do: state_change(data, process, :running, :complete)

    def after_read_hook(data),
      do: data
  end

  defimpl Helix.Process.Public.View.ProcessViewable do
    
  end
end
