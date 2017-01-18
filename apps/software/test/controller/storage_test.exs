defmodule Helix.Software.Controller.StorageTest do

  use ExUnit.Case, async: true

  alias HELL.IPv6
  alias Helix.Software.Controller.Storage, as: StorageController

  test "create/1" do
    assert {:ok, _} = StorageController.create()
  end

  describe "find/1" do
    test "success" do
      {:ok, storage} = StorageController.create()
      assert {:ok, ^storage} = StorageController.find(storage.storage_id)
    end

    test "failure" do
      assert {:error, :notfound} == StorageController.find(IPv6.generate([]))
    end
  end

  test "delete/2 idempotency" do
    {:ok, storage} = StorageController.create()

    assert :ok = StorageController.delete(storage.storage_id)
    assert :ok = StorageController.delete(storage.storage_id)

    assert {:error, :notfound} == StorageController.find(storage.storage_id)
  end
end