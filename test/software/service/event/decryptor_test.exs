defmodule Helix.Software.Service.Event.DecryptorTest do

  use Helix.Test.IntegrationCase

  alias HELL.TestHelper.Random
  alias Helix.Event
  alias Helix.Software.Controller.CryptoKey, as: CryptoKeyController
  alias Helix.Software.Model.CryptoKey
  alias Helix.Software.Model.File
  alias Helix.Software.Model.SoftwareType.Decryptor.ProcessConclusionEvent
  alias Helix.Software.Repo

  alias Helix.Software.Factory

  describe "when decryption is global" do
    test "on conclusion, removes the crypto version of the target file" do
      target_file = Factory.insert(:file, crypto_version: 6)
      event = %ProcessConclusionEvent{
        scope: :global,
        target_file_id: target_file.file_id,
        storage_id: Random.pk(),
        target_server_id: Random.pk()
      }

      Event.emit(event)

      # Let's give it enough time to run
      :timer.sleep(100)

      target_file = Repo.get(File, target_file.file_id)
      refute target_file.crypto_version
    end

    test "on conclusion, invalidates all keys that existed for a certain event" do
      target_file = Factory.insert(:file, crypto_version: 6)
      event = %ProcessConclusionEvent{
        scope: :global,
        target_file_id: target_file.file_id,
        storage_id: Random.pk(),
        target_server_id: Random.pk()
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

  describe "when decryption is local" do
    test "creates a new key file on storage that binds to target_file" do
      storage = Factory.insert(:storage, files: [])
      target_file = Factory.insert(:file)
      server_id = Random.pk()
      event = %ProcessConclusionEvent{
        scope: :local,
        target_file_id: target_file.file_id,
        target_server_id: server_id,
        storage_id: storage.storage_id
      }

      Event.emit(event)

      # Let's give it enough time to run
      :timer.sleep(100)

      [key] = CryptoKeyController.get_on_storage(storage)

      assert target_file.file_id == key.target_file_id
      assert server_id == key.target_server_id
    end
  end
end
