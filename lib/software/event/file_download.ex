defmodule Helix.Software.Event.FileDownload do

  alias Helix.Software.Query.File, as: FileQuery
  alias Helix.Software.Action.File, as: FileAction
  alias Helix.Software.Query.Storage, as: StorageQuery
  alias Helix.Software.Model.SoftwareType.FileDownload.ProcessConclusionEvent
  alias Helix.Software.Repo

  # TODO: Copy "FileModule" from origin file
  def complete(event = %ProcessConclusionEvent{}) do
    transaction = fn ->
      origin_file = FileQuery.fetch(event.from_file_id)

      destination_storage = StorageQuery.fetch(event.to_storage_id)

      # Who needs space checks, eh ? (TODO?)
      {:ok, _} = FileAction.copy(origin_file, destination_storage, "/Downloads")

      []
    end

    {:ok, _events} = Repo.transaction(transaction)
  end
end
