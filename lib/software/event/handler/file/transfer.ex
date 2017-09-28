defmodule Helix.Software.Event.Handler.File.Transfer do

  alias HELL.Constant
  alias Helix.Event
  alias Helix.Software.Action.File, as: FileAction
  alias Helix.Software.Query.File, as: FileQuery
  alias Helix.Software.Query.Storage, as: StorageQuery

  alias Helix.Software.Event.File.Transfer.Processed,
    as: FileTransferProcessedEvent
  alias Helix.Software.Event.File.Downloaded, as: FileDownloadedEvent
  alias Helix.Software.Event.File.DownloadFailed, as: FileDownloadFailedEvent
  alias Helix.Software.Event.File.Uploaded, as: FileUploadedEvent
  alias Helix.Software.Event.File.UploadFailed, as: FileUploadFailedEvent

  @type status :: :completed | :failed
  @type reason :: Constant.t

  def complete(event = %FileTransferProcessedEvent{}) do
    path = "/Downloads"

    with \
      source_file = %{} <- FileQuery.fetch(event.file_id),
      storage = %{} <- StorageQuery.fetch(event.to_storage_id),
      {:ok, file} <- FileAction.copy(source_file, storage, path)
    do
      event
      |> get_event(:completed, file)
      |> Event.emit()

      {:ok, file}
    else
      error ->
        event
        |> get_event(:failed, error)
        |> Event.emit()

        error
    end
  end

  @spec get_event(FileTransferProcessedEvent.t, status, File.t | reason) ::
    FileDownloadedEvent.t
    | FileDownloadFailedEvent.t
    | FileUploadedEvent.t
    | FileUploadFailedEvent.t
  defp get_event(event = %{type: :download}, :completed, file) do
    %FileDownloadedEvent{
      entity_id: event.entity_id,
      to_server_id: event.to_server_id,
      from_server_id: event.from_server_id,
      network_id: event.network_id,
      connection_type: event.connection_type,
      file_id: file.file_id
    }
  end
  defp get_event(event = %{type: :download}, :failed, reason) do
    %FileDownloadFailedEvent{
      entity_id: event.entity_id,
      to_server_id: event.to_server_id,
      from_server_id: event.from_server_id,
      network_id: event.network_id,
      connection_type: event.connection_type,
      reason: reason
    }
  end
  defp get_event(event = %{type: :upload}, :completed, file) do
    %FileUploadedEvent{
      entity_id: event.entity_id,
      to_server_id: event.to_server_id,
      from_server_id: event.from_server_id,
      network_id: event.network_id,
      file_id: file.file_id
    }
  end
  defp get_event(event = %{type: :upload}, :failed, reason) do
    %FileUploadFailedEvent{
      entity_id: event.entity_id,
      to_server_id: event.to_server_id,
      from_server_id: event.from_server_id,
      network_id: event.network_id,
      reason: reason
    }
  end
end
