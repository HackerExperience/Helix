# defmodule Helix.Software.Event.Handler.Encryptor do

#   alias Helix.Event
#   alias Helix.Software.Model.SoftwareType.Encryptor.ProcessConclusionEvent
#   alias Helix.Software.Action.CryptoKey, as: CryptoKeyAction
#   alias Helix.Software.Query.File, as: FileQuery
#   alias Helix.Software.Action.File, as: FileAction
#   alias Helix.Software.Query.Storage, as: StorageQuery
#   alias Helix.Software.Repo

#   def complete(event = %ProcessConclusionEvent{}) do
#     storage = StorageQuery.fetch(event.storage_id)
#     target_file = FileQuery.fetch(event.target_file_id)
#     target_server_id = event.target_server_id

#     transaction = fn ->
#       events = CryptoKeyAction.invalidate_keys_for_file(target_file)

#       {:ok, _} = FileAction.encrypt(target_file, event.version)
#       {:ok, _} = CryptoKeyAction.create(storage, target_server_id, target_file)

#       events
#     end

#     case Repo.transaction(transaction) do
#       {:ok, events} ->
#         Event.emit(events)
#     end
#   end
# end
