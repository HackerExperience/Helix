defmodule Helix.Software.Event.DecryptorTest do

  use Helix.Test.IntegrationCase

  alias Helix.Event
  alias Helix.Server.Model.Server
  alias Helix.Software.Internal.CryptoKey, as: CryptoKeyInternal
  alias Helix.Software.Model.CryptoKey
  alias Helix.Software.Model.File
  alias Helix.Software.Model.SoftwareType.Decryptor.ProcessConclusionEvent
  alias Helix.Software.Model.Storage
  alias Helix.Software.Repo

  alias Helix.Software.Factory

  describe "when decryption is global" do
    test "on conclusion, removes the crypto version of the target file" do
      target_file = Factory.insert(:file, crypto_version: 6)
      event = %ProcessConclusionEvent{
        scope: :global,
        target_file_id: target_file.file_id,
        storage_id: Storage.ID.generate(),
        target_server_id: Server.ID.generate()
      }

      Event.emit(event)

      target_file = Repo.get(File, target_file.file_id)
      refute target_file.crypto_version
    end

    test "on conclusion, invalidates all keys that existed for a certain event" do
      target_file = Factory.insert(:file, crypto_version: 6)
      event = %ProcessConclusionEvent{
        scope: :global,
        target_file_id: target_file.file_id,
        storage_id: Storage.ID.generate(),
        target_server_id: Server.ID.generate()
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

  describe "when decryption is local" do
    test "creates a new key file on storage that binds to target_file" do
      storage = Factory.insert(:storage, files: [])
      target_file = Factory.insert(:file)
      server_id = Server.ID.generate()
      event = %ProcessConclusionEvent{
        scope: :local,
        target_file_id: target_file.file_id,
        target_server_id: server_id,
        storage_id: storage.storage_id
      }

      Event.emit(event)

      [key] = CryptoKeyInternal.get_on_storage(storage)

      assert target_file.file_id == key.target_file_id
      assert server_id == key.target_server_id
    end
  end
end
