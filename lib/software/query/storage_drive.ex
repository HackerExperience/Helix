defmodule Helix.Software.Query.StorageDrive do

  alias Helix.Software.Internal.StorageDrive, as: StorageDriveInternal
  alias Helix.Software.Model.Storage

  @spec get_storage_drives(Storage.t) :: [HELL.PK.t]
  def get_storage_drives(storage) do
    StorageDriveInternal.get_storage_drives(storage)
  end
end
