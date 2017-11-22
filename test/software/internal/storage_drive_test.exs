defmodule Helix.Software.Internal.StorageDriveTest do

  use Helix.Test.Case.Integration

  alias Helix.Server.Model.Component
  alias Helix.Software.Internal.StorageDrive, as: StorageDriveInternal

  alias Helix.Test.Cache.Helper, as: CacheHelper
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  test "linking succeeds with a valid storage" do
    drive_id = Component.ID.generate()
    {storage, _} = SoftwareSetup.storage()

    StorageDriveInternal.link_drive(storage, drive_id)

    assert drive_id in StorageDriveInternal.get_storage_drives(storage)

    CacheHelper.sync_test()
  end

  describe "getting" do
    test "returns every drive of given storage" do
      {storage, _} = SoftwareSetup.storage()

      expected_drives =
        1..3
        |> Enum.map(fn _ ->
          drive_id = Component.ID.generate()
          StorageDriveInternal.link_drive(storage, drive_id)
          drive_id
        end)

      storage_drives = StorageDriveInternal.get_storage_drives(storage)

      Enum.each(expected_drives, fn drive_id ->
        assert drive_id in storage_drives
      end)
    end

    test "returns an empty list when storage has no drives" do
      {storage, _} = SoftwareSetup.storage()

      # Remove drive from storage
      [drive_id] = StorageDriveInternal.get_storage_drives(storage)
      StorageDriveInternal.unlink_drive(drive_id)

      got_drives = StorageDriveInternal.get_storage_drives(storage)
      assert Enum.empty?(got_drives)

      CacheHelper.sync_test()
    end
  end

  test "unlinking removes storage_drive" do
    {storage, _} = SoftwareSetup.storage()

    [drive_id] = StorageDriveInternal.get_storage_drives(storage)

    assert drive_id in StorageDriveInternal.get_storage_drives(storage)
    StorageDriveInternal.unlink_drive(drive_id)
    refute drive_id in StorageDriveInternal.get_storage_drives(storage)

    CacheHelper.sync_test()
  end
end
