defmodule Helix.Software.Controller.StorageDriveTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Software.Controller.StorageDrive, as: StorageDriveController

  alias Helix.Software.Factory

  @moduletag :integration

  describe "creating" do
    test "succeeds with valid params" do
      storage = Factory.insert(:storage)

      params = %{
        drive_id: Random.pk(),
        storage_id: storage.storage_id
      }

      assert {:ok, _} = StorageDriveController.create(params)
    end

    test "fails if storage with id doesn't exist" do
      storage = Factory.build(:storage)

      bogus = %{
        drive_id: Random.pk(),
        storage_id: storage.storage_id
      }

      assert {:error, cs} = StorageDriveController.create(bogus)
      assert :storage_id in Keyword.keys(cs.errors)
    end
  end

  describe "finding" do
    test "returns a list containing records based on its relationship" do
      storage = Factory.insert(:storage)
      expected_drives = MapSet.new(storage.drives)
      received_drives =
        [storage: storage]
        |> StorageDriveController.find()
        |> MapSet.new()

      assert MapSet.equal?(expected_drives, received_drives)
    end

    test "returns an empty list when no relationship exists" do
      storage = Factory.insert(:storage, drives: [])
      assert [] == StorageDriveController.find(storage: storage)
    end
  end

  test "deleting is idempotent" do
    drive =
      :storage
      |> Factory.insert()
      |> Map.fetch!(:drives)
      |> Enum.random()

    drives = StorageDriveController.find(storage: drive.storage_id)
    assert drive in drives

    StorageDriveController.delete(drive.storage_id, drive.drive_id)
    StorageDriveController.delete(drive.storage_id, drive.drive_id)

    drives = StorageDriveController.find(storage: drive.storage_id)
    refute drive in drives
  end
end
