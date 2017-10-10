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

  @doc """
  Handles the completion of the `FileTransferProcess`.

  Emits:
  FileDownloadedEvent | FileUploadedEvent, in case of success;
  FileDownloadFailedEvent | FileUploadFailedEvent, in case of failure
  """
  def complete(event = %FileTransferProcessedEvent{}) do
    create_params = fn file ->
      %{
        path: "/Downloads",
        name: file.name
      }
    end

    with \
      source_file = %{} <- FileQuery.fetch(event.file_id),
      storage = %{} <- StorageQuery.fetch(event.to_storage_id),
      params = create_params.(source_file),
      {:ok, file} <- FileAction.copy(source_file, storage, params)
    do
      event
      |> get_event(:completed, file)
      |> Event.emit()

      {:ok, file}
    else
      _error ->
        error = :unknown  # TODO

        event
        |> get_event(:failed, error)
        |> Event.emit()

        {:error, error}
    end
  end

  @spec get_event(FileTransferProcessedEvent.t, status, term) ::
    FileDownloadedEvent.t
    | FileDownloadFailedEvent.t
    | FileUploadedEvent.t
    | FileUploadFailedEvent.t
  defp get_event(transfer = %{type: :download}, :completed, file),
    do: FileDownloadedEvent.new(transfer, file)
  defp get_event(transfer = %{type: :download}, :failed, reason),
    do: FileDownloadFailedEvent.new(transfer, reason)
  defp get_event(transfer = %{type: :upload}, :completed, file),
    do: FileUploadedEvent.new(transfer, file)
  defp get_event(transfer = %{type: :upload}, :failed, reason),
    do: FileUploadFailedEvent.new(transfer, reason)
end
