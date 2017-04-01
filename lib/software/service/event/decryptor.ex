defmodule Helix.Software.Service.Event.Decryptor do

  alias Helix.Event
  alias Helix.Software.Model.SoftwareType.Decryptor.ProcessConclusionEvent
  alias Helix.Software.Controller.CryptoKey
  alias Helix.Software.Controller.File
  alias Helix.Software.Controller.Storage
  alias Helix.Software.Repo

  @spec complete(%ProcessConclusionEvent{}) :: any
  def complete(event = %ProcessConclusionEvent{scope: :global}) do
    target_file = File.fetch(event.target_file_id)

    transaction = fn ->
      events = CryptoKey.invalidate_keys_for_file(target_file)

      {:ok, _} = File.decrypt(target_file)

      events
    end

    {:ok, events} = Repo.transaction(transaction)
    emit(events)
  end

  def complete(event = %ProcessConclusionEvent{scope: :local}) do
    storage = Storage.fetch(event.storage_id)
    target_file = File.fetch(event.target_file_id)
    target_server_id = event.target_server_id

    transaction = fn ->
      {:ok, _} = CryptoKey.create(storage, target_server_id, target_file)
    end

    {:ok, _} = Repo.transaction(transaction)
  end

  defp emit(events),
    do: events |> List.wrap() |> Enum.each(&Event.emit/1)
end
