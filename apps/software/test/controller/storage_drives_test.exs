defmodule HELM.Software.Controller.StorageDrivesTest do
  use ExUnit.Case

  alias HELL.Random, as: HRand

  alias HELM.Software.Storage.Controller, as: StorageCtrl
  alias HELM.Software.Storage.Drive.Controller, as: StorageDriveCtrl

  describe "creation" do
    test "success" do
      {:ok, storage} = StorageCtrl.create()
      assert {:ok, _} = StorageDriveCtrl.create(HRand.random_number, storage.storage_id)
    end
  end

  describe "search" do
    test "success" do
      {:ok, storage} = StorageCtrl.create()
      {:ok, drive} = StorageDriveCtrl.create(HRand.random_number, storage.storage_id)
      assert {:ok, drive} = StorageDriveCtrl.find(drive.drive_id)
    end
  end

  describe "removal" do
    test "success" do
      {:ok, storage} = StorageCtrl.create()
      {:ok, drive} = StorageDriveCtrl.create(HRand.random_number, storage.storage_id)
      assert {:ok, _} = StorageDriveCtrl.delete(drive.drive_id)
    end
  end
end