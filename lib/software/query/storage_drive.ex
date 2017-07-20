defmodule Helix.Software.Query.StorageDrive do

  # REVIEW: Merge this with Query.Storage ?

  alias Helix.Hardware.Model.Component
  alias Helix.Software.Internal.StorageDrive, as: StorageDriveInternal
  alias Helix.Software.Model.Storage

  @spec get_storage_drives(Storage.t) ::
    [Component.id]
  defdelegate get_storage_drives(storage),
    to: StorageDriveInternal
end
