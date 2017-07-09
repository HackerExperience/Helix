defmodule Helix.Software.Action.StorageDrive do

  alias Helix.Software.Internal.StorageDrive, as: StorageDriveInternal
  alias Helix.Software.Model.Storage

  @spec link_drive(Storage.t, HELL.PK.t) :: :ok | {:error, reason :: term}
  def link_drive(storage, drive_id) do
    StorageDriveInternal.link_drive(storage, drive_id)
  end

  @spec unlink_drive(HELL.PK.t) :: :ok
  def unlink_drive(drive_id) do
    StorageDriveInternal.unlink_drive(drive_id)

    :ok
  end
end
