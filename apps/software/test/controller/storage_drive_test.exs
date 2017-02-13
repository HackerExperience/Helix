defmodule Helix.Software.Controller.StorageDriveTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Software.Controller.StorageDrive, as: StorageDriveController

  alias Helix.Software.Factory

  test "create/1" do
    storage = Factory.insert(:storage)
    highest_drive_id =
      storage.drives
      |> Enum.map(&(&1.drive_id))
      |> Enum.reduce(0, &max/2)

    payload = %{
      drive_id: highest_drive_id + 1,
      storage_id: storage.storage_id
    }

    assert {:ok, _} = StorageDriveController.create(payload)
  end

  describe "find/2" do
    test "success" do
      drive = create_drive()
      assert {:ok, ^drive} = StorageDriveController.find(drive.storage_id, drive.drive_id)
    end

    test "failure" do
      assert {:error, :notfound} == StorageDriveController.find(Random.pk(), 1)
    end
  end

  test "delete/2 idempotency" do
    drive = create_drive()

    assert :ok = StorageDriveController.delete(drive.storage_id, drive.drive_id)
    assert :ok = StorageDriveController.delete(drive.storage_id, drive.drive_id)

    assert {:error, :notfound} == StorageDriveController.find(drive.storage_id, drive.drive_id)
  end

  defp create_drive do
    :storage
    |> Factory.insert()
    |> Map.fetch!(:drives)
    |> Enum.random()
  end
end