defmodule Helix.Software.Controller.StorageDriveTest do

  use ExUnit.Case, async: true

  alias HELL.PK
  alias HELL.TestHelper.Random, as: HRand
  alias Helix.Software.Controller.Storage, as: StorageController
  alias Helix.Software.Controller.StorageDrive, as: StorageDriveController

  setup do
    {:ok, storage} = StorageController.create()

    payload = %{
      drive_id: HRand.number(),
      storage_id: storage.storage_id
    }

    {:ok, payload: payload}
  end

  test "create/1", %{payload: payload} do
    assert {:ok, _} = StorageDriveController.create(payload)
  end

  describe "find/2" do
    test "success", %{payload: payload} do
      assert {:ok, drive} = StorageDriveController.create(payload)
      assert {:ok, ^drive} = StorageDriveController.find(drive.storage_id, drive.drive_id)
    end

    test "failure" do

      assert {:error, :notfound} == StorageDriveController.find(PK.generate([]), 0)
    end
  end

  test "delete/2 idempotency", %{payload: payload} do
    assert {:ok, drive} = StorageDriveController.create(payload)

    assert :ok = StorageDriveController.delete(drive.storage_id, drive.drive_id)
    assert :ok = StorageDriveController.delete(drive.storage_id, drive.drive_id)

    assert {:error, :notfound} == StorageDriveController.find(drive.storage_id, drive.drive_id)
  end
end