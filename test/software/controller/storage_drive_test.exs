defmodule Helix.Software.Controller.StorageDriveTest do

  use Helix.Test.IntegrationCase

  alias HELL.TestHelper.Random
  alias Helix.Software.Controller.StorageDrive, as: Controller

  alias Helix.Software.Factory

  test "linking succeeds with a valid storage" do
    drive_id = Random.pk()
    storage = Factory.insert(:storage, %{drives: []})

    Controller.link_drive(storage, drive_id)

    assert drive_id in Controller.get_storage_drives(storage)
  end

  describe "getting" do
    test "returns every drive of given storage" do
      storage = Factory.insert(:storage, %{drives: []})
      expected_drives =
        3
        |> Factory.insert_list(:storage_drive, storage: storage)
        |> Enum.map(&(&1.drive_id))

      got_drives = Controller.get_storage_drives(storage)
      assert Enum.sort(expected_drives) == Enum.sort(got_drives)
    end

    test " returns an empty list when storage has no drives" do
      driveless_storage = Factory.insert(:storage, %{drives: []})
      got_drives = Controller.get_storage_drives(driveless_storage)

      assert Enum.empty?(got_drives)
    end
  end

  test "unlinking is idempotent" do
    %{storage: storage, drive_id: drive_id} = Factory.insert(:storage_drive)

    assert drive_id in Controller.get_storage_drives(storage)
    Controller.unlink_drive(drive_id)
    Controller.unlink_drive(drive_id)
    refute drive_id in Controller.get_storage_drives(storage)
  end
end
