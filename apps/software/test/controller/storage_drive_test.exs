defmodule HELM.Software.Controller.StorageDriveTest do
  use ExUnit.Case

  alias HELL.Random, as: HRand

  alias HELM.Software.Controller.Storage, as: CtrlStorage
  alias HELM.Software.Controller.StorageDrive, as: CtrlStorageDrives

  describe "creation" do
    test "success" do
      {:ok, storage} = CtrlStorage.create()
      assert {:ok, _} = CtrlStorageDrives.create(HRand.random_number, storage.storage_id)
    end
  end

  describe "search" do
    test "success" do
      {:ok, storage} = CtrlStorage.create()
      {:ok, drive} = CtrlStorageDrives.create(HRand.random_number, storage.storage_id)
      assert {:ok, ^drive} = CtrlStorageDrives.find(drive.drive_id)
    end
  end

  describe "removal" do
    test "success" do
      {:ok, storage} = CtrlStorage.create()
      {:ok, drive} = CtrlStorageDrives.create(HRand.random_number, storage.storage_id)
      assert {:ok, _} = CtrlStorageDrives.delete(drive.drive_id)
    end
  end
end