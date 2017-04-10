defmodule Helix.Software.Service.Event.EncryptorTest do

  use Helix.Test.IntegrationCase

  alias HELL.TestHelper.Random
  alias Helix.Event
  alias Helix.Software.Controller.CryptoKey, as: CryptoKeyController
  alias Helix.Software.Model.CryptoKey
  alias Helix.Software.Model.File
  alias Helix.Software.Model.SoftwareType.Encryptor.ProcessConclusionEvent
  alias Helix.Software.Repo

  alias Helix.Software.Factory

  describe "when process is completed" do
    test "creates a new key file on storage that binds to target_file" do
      storage = Factory.insert(:storage, files: [])
      target_file = Factory.insert(:file)
      server_id = Random.pk()
      event = %ProcessConclusionEvent{
        target_file_id: target_file.file_id,
        target_server_id: server_id,
        storage_id: storage.storage_id,
        version: Enum.random(1..32)
      }

      Event.emit(event)

      # Let's give it enough time to run
      :timer.sleep(100)

      [key] = CryptoKeyController.get_on_storage(storage)

      assert target_file.file_id == key.target_file_id
      assert server_id == key.target_server_id
    end

    test "changes the crypto version of the target file" do
      storage = Factory.insert(:storage, files: [])
      target_file = Factory.insert(:file)
      server_id = Random.pk()
      event = %ProcessConclusionEvent{
        target_file_id: target_file.file_id,
        target_server_id: server_id,
        storage_id: storage.storage_id,
        version: Enum.random(1..32)
      }

      Event.emit(event)

      # Let's give it enough time to run
      :timer.sleep(100)

      target_file = Repo.get(File, target_file.file_id)
      assert event.version == target_file.crypto_version
    end

    test "invalidates all keys that existed for a certain event" do
      storage = Factory.insert(:storage, files: [])
      target_file = Factory.insert(:file)
      server_id = Random.pk()
      event = %ProcessConclusionEvent{
        target_file_id: target_file.file_id,
        target_server_id: server_id,
        storage_id: storage.storage_id,
        version: Enum.random(1..32)
      }

      # Create several keys for the file
      storages_that_had_key = Factory.insert_list(5, :storage, files: [])
      create_key = &CryptoKeyController.create(&1, Random.pk(), target_file)
      old_keys =
        storages_that_had_key
        |> Enum.map(create_key)
        |> Enum.map(fn {:ok, key} -> key end)

      Event.emit(event)

      # Let's give it enough time to run
      :timer.sleep(100)

      new_keys = Enum.map(old_keys, &Repo.get(CryptoKey, &1.file_id))

      assert Enum.all?(new_keys, &is_nil(&1.target_file_id))
    end
  end
end
