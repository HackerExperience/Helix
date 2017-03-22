defmodule Helix.Software.Controller.StorageDriveTest do

  use ExUnit.Case, async: true

  alias HELL.PK
  alias Helix.Hardware.Model.Component
  alias Helix.Software.Controller.StorageDrive, as: Controller

  alias Helix.Software.Factory

  defp create_storage do
    :storage
    |> Factory.build()
    |> Map.put(:drives, [])
    |> Factory.insert()
  end

  test "linking succeeds with a valid storage" do
    drive_id = PK.pk_for(Component)
    storage = create_storage()

    Controller.link_drive(storage, drive_id)

    assert drive_id in Controller.get_storage_drives(storage)
  end

  test "getting returns every drive of given storage" do
    storage = create_storage()
    expected_drives =
      3
      |> Factory.insert_list(:storage_drive, storage: storage)
      |> Enum.map(&(&1.drive_id))

    got_drives = Controller.get_storage_drives(storage)

    refute Enum.empty?(expected_drives)
    assert Enum.empty?(expected_drives -- got_drives)

    driveless_storage = create_storage()
    got_drives = Controller.get_storage_drives(driveless_storage)

    assert Enum.empty?(got_drives)
  end

  test "unlinking is idempotent" do
    %{storage: storage, drive_id: drive_id} = Factory.insert(:storage_drive)

    Controller.unlink_drive(drive_id)
    Controller.unlink_drive(drive_id)

    refute drive_id in Controller.get_storage_drives(storage)
  end
end