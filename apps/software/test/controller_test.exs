defmodule HELM.Software.ControllerTest do
  use ExUnit.Case

  alias HELF.Broker
  alias HELM.Software.Storage.Controller, as: SoftStorageCtrl
  alias HELM.Software.Storage.Drive.Controller, as: SoftStorageDriveCtrl

  def random_num do
    :rand.uniform(134217727)
  end

  def random_str do
    random_num()
    |> Integer.to_string
  end

  describe "HELM.Software.Storage.Controller" do
    test "create/0 success" do
      assert {:ok, _} = SoftStorageCtrl.create()
    end

    test "find/1 success" do
      {:ok, storage} = SoftStorageCtrl.create()
      assert {:ok, storage} = SoftStorageCtrl.find(storage.storage_id)
    end

    test "delete/1 success" do
      {:ok, storage} = SoftStorageCtrl.create()
      assert {:ok, _} = SoftStorageCtrl.delete(storage.storage_id)
    end
  end

  describe "HELM.Software.Storage.Drive.Controller" do
    test "create/1 success" do
      {:ok, storage} = SoftStorageCtrl.create()
      assert {:ok, _} = SoftStorageDriveCtrl.create(random_num, storage.storage_id)
    end

    test "find/1 success" do
      {:ok, storage} = SoftStorageCtrl.create()
      {:ok, drive} = SoftStorageDriveCtrl.create(random_num, storage.storage_id)
      assert {:ok, drive} = SoftStorageDriveCtrl.find(drive.drive_id)
    end

    test "delete/1 success" do
      {:ok, storage} = SoftStorageCtrl.create()
      {:ok, drive} = SoftStorageDriveCtrl.create(random_num, storage.storage_id)
      assert {:ok, _} = SoftStorageDriveCtrl.delete(drive.drive_id)
    end
  end

end
