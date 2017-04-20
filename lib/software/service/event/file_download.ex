defmodule Helix.Software.Service.Event.FileDownload do

  alias Helix.Software.Controller.File
  alias Helix.Software.Controller.Storage
  alias Helix.Software.Model.SoftwareType.FileDownload.ProcessConclusionEvent
  alias Helix.Software.Repo

  # TODO: Copy "FileModule" from origin file
  def complete(event = %ProcessConclusionEvent{}) do
    transaction = fn ->
      origin_file = File.fetch(event.target_file_id)

      destination_storage = Storage.fetch(event.destination_storage_id)

      # Who needs space checks, eh ?
      {:ok, _} = File.copy(origin_file, destination_storage, "/Downloads")

      []
    end

    {:ok, _events} = Repo.transaction(transaction)
  end
end
