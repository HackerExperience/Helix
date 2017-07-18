defmodule Helix.Software.Query.StorageDrive do

  # REVIEW: Merge this with Query.Storage ?

  alias Helix.Hardware.Model.Component
  alias Helix.Software.Model.Storage
  alias Helix.Software.Query.StorageDrive.Origin, as: StorageDriveQueryOrigin

  @spec get_storage_drives(Storage.t) ::
    [Component.id]
  defdelegate get_storage_drives(storage),
    to: StorageDriveQueryOrigin

  defmodule Origin do
    alias Helix.Software.Internal.StorageDrive, as: StorageDriveInternal

    def get_storage_drives(storage) do
      StorageDriveInternal.get_storage_drives(storage)
    end

  end
end
