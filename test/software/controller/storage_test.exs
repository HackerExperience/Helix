defmodule Helix.Software.Controller.StorageTest do

  use Helix.Test.IntegrationCase

  alias HELL.TestHelper.Random
  alias Helix.Software.Controller.Storage, as: StorageController
  alias Helix.Software.Model.Storage

  alias Helix.Software.Factory

  # REVIEW: Is this is a good test name, it's weird?
  test "creating always succeeds" do
    assert {:ok, _} = StorageController.create()
  end

  describe "fetching" do
    test "returns a record based on its identification" do
      storage = Factory.insert(:storage)
      assert %Storage{} = StorageController.fetch(storage.storage_id)
    end

    test "returns nil if storage with id doesn't exists" do
      storage_id = Random.pk()
      refute StorageController.fetch(storage_id)
    end
  end

  test "deleting is idempotency" do
    # Create a Storage without any files being contained by it since (right now)
    # you can't directly delete an storage without deleting it's files
    storage = Factory.insert(:storage, %{files: []})

    assert StorageController.fetch(storage.storage_id)
    assert :ok = StorageController.delete(storage.storage_id)
    assert :ok = StorageController.delete(storage.storage_id)
    refute StorageController.fetch(storage.storage_id)
  end
end
