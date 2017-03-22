defmodule Helix.Software.Controller.StorageTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Software.Controller.Storage, as: StorageController

  alias Helix.Software.Factory

  @moduletag :integration

  test "create/1" do
    assert {:ok, _} = StorageController.create()
  end

  describe "find/1" do
    test "success" do
      storage = Factory.insert(:storage)
      {:ok, found} = StorageController.find(storage.storage_id)

      assert storage.storage_id == found.storage_id
    end

    test "failure" do
      assert {:error, :notfound} == StorageController.find(Random.pk())
    end
  end

  test "delete/2 idempotency" do
    # Create a Storage without any files being contained by it since (right now)
    # you can't directly delete an storage without deleting it's files
    storage =
      :storage
      |> Factory.build()
      |> Map.put(:files, [])
      |> Factory.insert()

    assert :ok = StorageController.delete(storage.storage_id)
    assert :ok = StorageController.delete(storage.storage_id)

    assert {:error, :notfound} == StorageController.find(storage.storage_id)
  end
end