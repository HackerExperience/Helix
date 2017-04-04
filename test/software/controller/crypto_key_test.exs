defmodule Helix.Software.Controller.CryptoKeyTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Software.Controller.CryptoKey, as: CryptoKeyController
  alias Helix.Software.Controller.File, as: FileController
  alias Helix.Software.Model.CryptoKey.InvalidatedEvent

  alias Helix.Software.Factory

  @moduletag :integration

  describe "create/3" do
    test "will create a file for the key on storage" do
      storage = Factory.insert(:storage, %{files: []})
      random_files = Factory.insert_list(5, :file, %{crypto_version: 1})
      server_id = Random.pk()

      create_key = &CryptoKeyController.create(storage, server_id, &1)
      Enum.each(random_files, create_key)

      files = FileController.get_files_on_target_storage(storage)

      assert 5 == Enum.count(files)
      assert Enum.all?(files, &(&1.software_type == :crypto_key))
    end
  end

  describe "invalidate_keys_for_file/1" do
    test "will unlink any key that is bound to target file" do
      storages = Factory.insert_list(3, :storage, %{files: []})
      file = Factory.insert(:file, %{crypto_version: 1})

      create_key_for_file = &CryptoKeyController.create(&1, Random.pk(), file)
      Enum.each(storages, create_key_for_file)

      keys_before = Enum.flat_map(
        storages,
        &CryptoKeyController.get_on_storage/1)

      CryptoKeyController.invalidate_keys_for_file(file)

      keys_after = Enum.flat_map(
        storages,
        &CryptoKeyController.get_on_storage/1)

      refute Enum.any?(keys_before, &is_nil(&1.target_file_id))
      assert Enum.all?(keys_after, &is_nil(&1.target_file_id))
    end

    test "returns an event for each invalidated key" do
      storages = Factory.insert_list(3, :storage, %{files: []})
      file = Factory.insert(:file, %{crypto_version: 1})

      create_key_for_file = &CryptoKeyController.create(&1, Random.pk(), file)
      Enum.each(storages, create_key_for_file)

      events = CryptoKeyController.invalidate_keys_for_file(file)

      assert 3 == Enum.count(events)
      assert Enum.all?(events, &match?(%InvalidatedEvent{}, &1))
    end
  end
end
