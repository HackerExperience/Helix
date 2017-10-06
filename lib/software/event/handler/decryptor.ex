defmodule Helix.Software.Event.Handler.Decryptor do

  alias Helix.Event
  alias Helix.Software.Model.SoftwareType.Decryptor.ProcessConclusionEvent
  alias Helix.Software.Action.CryptoKey, as: CryptoKeyAction
  alias Helix.Software.Query.File, as: FileQuery
  alias Helix.Software.Action.File, as: FileAction
  alias Helix.Software.Query.Storage, as: StorageQuery
  alias Helix.Software.Repo

  def complete(event = %ProcessConclusionEvent{scope: :global}) do
    target_file = FileQuery.fetch(event.target_file_id)

    transaction = fn ->
      events = CryptoKeyAction.invalidate_keys_for_file(target_file)

      {:ok, _} = FileAction.decrypt(target_file)

      events
    end

    {:ok, events} = Repo.transaction(transaction)
    Event.emit(events)
  end

  def complete(event = %ProcessConclusionEvent{scope: :local}) do
    storage = StorageQuery.fetch(event.storage_id)
    target_file = FileQuery.fetch(event.target_file_id)
    target_server_id = event.target_server_id

    transaction = fn ->
      {:ok, _} = CryptoKeyAction.create(storage, target_server_id, target_file)
    end

    {:ok, _} = Repo.transaction(transaction)
  end
end
