defmodule Helix.Software.Action.StorageDrive do

  alias Helix.Hardware.Model.Component
  alias Helix.Software.Internal.StorageDrive, as: StorageDriveInternal
  alias Helix.Software.Model.Storage

  @spec link_drive(Storage.t, Component.id) ::
    :ok
    | {:error, reason :: term}
  defdelegate link_drive(storage, drive_id),
    to: StorageDriveInternal

  @spec unlink_drive(Component.id) ::
    :ok
  defdelegate unlink_drive(drive_id),
    to: StorageDriveInternal
end
