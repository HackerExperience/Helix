defmodule Helix.Software.Service.Event.Encryptor do

  alias Helix.Event
  alias Helix.Software.Model.SoftwareType.Encryptor.ProcessConclusionEvent
  alias Helix.Software.Controller.CryptoKey
  alias Helix.Software.Controller.File
  alias Helix.Software.Controller.Storage
  alias Helix.Software.Repo

  @spec complete(%ProcessConclusionEvent{}) :: any
  def complete(event = %ProcessConclusionEvent{}) do
    storage = Storage.fetch(event.storage_id)
    target_file = File.fetch(event.target_file_id)
    target_server_id = event.target_server_id

    transaction = fn ->
      events = CryptoKey.invalidate_keys_for_file(target_file)

      {:ok, _} = File.encrypt(target_file, event.version)
      {:ok, _} = CryptoKey.create(storage, target_server_id, target_file)

      events
    end

    case Repo.transaction(transaction) do
      {:ok, events} ->
        events
        |> List.wrap()
        |> Enum.each(&Event.emit/1)
    end
  end
end
