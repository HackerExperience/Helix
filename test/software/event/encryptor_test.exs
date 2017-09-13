defmodule Helix.Software.Event.EncryptorTest do

  use Helix.Test.Case.Integration

  alias Helix.Event
  alias Helix.Server.Model.Server
  alias Helix.Software.Internal.CryptoKey, as: CryptoKeyInternal
  alias Helix.Software.Model.CryptoKey
  alias Helix.Software.Model.File
  alias Helix.Software.Model.SoftwareType.Encryptor.ProcessConclusionEvent
  alias Helix.Software.Repo

  alias Helix.Test.Software.Factory

  describe "when process is completed" do
    test "creates a new key file on storage that binds to target_file" do
      storage = Factory.insert(:storage, files: [])
      target_file = Factory.insert(:file)
      server_id = Server.ID.generate()
      event = %ProcessConclusionEvent{
        target_file_id: target_file.file_id,
        target_server_id: server_id,
        storage_id: storage.storage_id,
        version: Enum.random(1..32)
      }

      Event.emit(event)

      [key] = CryptoKeyInternal.get_on_storage(storage)

      assert target_file.file_id == key.target_file_id
      assert server_id == key.target_server_id
    end

    test "changes the crypto version of the target file" do
      storage = Factory.insert(:storage, files: [])
      target_file = Factory.insert(:file)
      server_id = Server.ID.generate()
      event = %ProcessConclusionEvent{
        target_file_id: target_file.file_id,
        target_server_id: server_id,
        storage_id: storage.storage_id,
        version: Enum.random(1..32)
      }

      Event.emit(event)

      target_file = Repo.get(File, target_file.file_id)
      assert event.version == target_file.crypto_version
    end

    test "invalidates all keys that existed for a certain event" do
      storage = Factory.insert(:storage, files: [])
      target_file = Factory.insert(:file)
      server_id = Server.ID.generate()
      event = %ProcessConclusionEvent{
        target_file_id: target_file.file_id,
        target_server_id: server_id,
        storage_id: storage.storage_id,
        version: Enum.random(1..32)
      }

      # Create several keys for the file
      storages_that_had_key = Factory.insert_list(5, :storage, files: [])
      server_id = Server.ID.generate()
      create_key = &CryptoKeyInternal.create(&1, server_id, target_file)
      old_keys =
        storages_that_had_key
        |> Enum.map(create_key)
        |> Enum.map(fn {:ok, key} -> key end)

      Event.emit(event)

      new_keys = Enum.map(old_keys, &Repo.get(CryptoKey, &1.file_id))

      assert Enum.all?(new_keys, &is_nil(&1.target_file_id))
    end
  end
end
