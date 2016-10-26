defmodule HELM.Software.Controller.StoragesTest do
  use ExUnit.Case
  alias HELM.Software.Controller.Storages, as: CtrlStorages

  describe "creation" do
    test "success" do
      assert {:ok, _} = CtrlStorages.create()
    end
  end

  describe "search" do
    test "success" do
      {:ok, storage} = CtrlStorages.create()
      assert {:ok, ^storage} = CtrlStorages.find(storage.storage_id)
    end
  end

  describe "removal" do
    test "success" do
      {:ok, storage} = CtrlStorages.create()
      assert {:ok, _} = CtrlStorages.delete(storage.storage_id)
    end
  end
end