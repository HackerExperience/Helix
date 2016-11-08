defmodule HELM.Software.Controller.StorageDriveTest do
  use ExUnit.Case

  alias HELL.IPv6
  alias HELL.TestHelper.Random, as: HRand
  alias HELM.Software.Controller.Storage, as: CtrlStorage
  alias HELM.Software.Controller.StorageDrive, as: CtrlStorageDrives

  setup do
    {:ok, storage} = CtrlStorage.create()

    payload = %{
      drive_id: HRand.number(),
      storage_id: storage.storage_id
    }

    {:ok, payload: payload}
  end

  test "create/1", %{payload: payload} do
    assert {:ok, _} = CtrlStorageDrives.create(payload)
  end

  describe "find/2" do
    test "success", %{payload: payload} do
      assert {:ok, drive} = CtrlStorageDrives.create(payload)
      assert {:ok, ^drive} = CtrlStorageDrives.find(drive.storage_id, drive.drive_id)
    end

    test "failure" do
      assert {:error, :notfound} = CtrlStorageDrives.find(IPv6.generate([]), 0)
    end
  end

  test "delete/2 idempotency", %{payload: payload} do
    assert {:ok, drive} = CtrlStorageDrives.create(payload)

    assert :ok = CtrlStorageDrives.delete(drive.storage_id, drive.drive_id)
    assert :ok = CtrlStorageDrives.delete(drive.storage_id, drive.drive_id)

    assert {:error, :notfound} = CtrlStorageDrives.find(drive.storage_id, drive.drive_id)
  end
end