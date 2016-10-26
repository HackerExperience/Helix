defmodule HELM.Software.Controller.StoragesTest do
  use ExUnit.Case
  alias HELM.Software.Storage.Controller, as: StorageCtrl

  describe "creation" do
    test "success" do
      assert {:ok, _} = StorageCtrl.create()
    end
  end

  describe "search" do
    test "success" do
      {:ok, storage} = StorageCtrl.create()
      assert {:ok, storage} = StorageCtrl.find(storage.storage_id)
    end
  end

  describe "removal" do
    test "success" do
      {:ok, storage} = StorageCtrl.create()
      assert {:ok, _} = StorageCtrl.delete(storage.storage_id)
    end
  end
end