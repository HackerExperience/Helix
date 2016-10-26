defmodule HELM.Software.Controller.StorageDrivesTest do
  use ExUnit.Case

  alias HELL.Random, as: HRand

  alias HELM.Software.Controller.Storages, as: CtrlStorages
  alias HELM.Software.Controller.StorageDrives, as: CtrlStorageDrives

  describe "creation" do
    test "success" do
      {:ok, storage} = CtrlStorages.create()
      assert {:ok, _} = CtrlStorageDrives.create(HRand.random_number, storage.storage_id)
    end
  end

  describe "search" do
    test "success" do
      {:ok, storage} = CtrlStorages.create()
      {:ok, drive} = CtrlStorageDrives.create(HRand.random_number, storage.storage_id)
      assert {:ok, ^drive} = CtrlStorageDrives.find(drive.drive_id)
    end
  end

  describe "removal" do
    test "success" do
      {:ok, storage} = CtrlStorages.create()
      {:ok, drive} = CtrlStorageDrives.create(HRand.random_number, storage.storage_id)
      assert {:ok, _} = CtrlStorageDrives.delete(drive.drive_id)
    end
  end
end