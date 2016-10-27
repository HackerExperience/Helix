defmodule HELM.Software.Controller.StorageTest do
  use ExUnit.Case
  alias HELM.Software.Controller.Storage, as: CtrlStorage

  describe "creation" do
    test "success" do
      assert {:ok, _} = CtrlStorage.create()
    end
  end

  describe "search" do
    test "success" do
      {:ok, storage} = CtrlStorage.create()
      assert {:ok, ^storage} = CtrlStorage.find(storage.storage_id)
    end
  end

  describe "removal" do
    test "success" do
      {:ok, storage} = CtrlStorage.create()
      assert {:ok, _} = CtrlStorage.delete(storage.storage_id)
    end
  end
end