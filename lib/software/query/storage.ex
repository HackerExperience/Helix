defmodule Helix.Software.Query.Storage do

  alias Helix.Software.Internal.Storage, as: StorageInternal
  alias Helix.Software.Model.Storage

  @spec fetch(HELL.PK.t) :: Storage.t | nil
  def fetch(storage_id),
    do: StorageInternal.fetch(storage_id)

  @spec get_storage_from_hdd(HELL.PK.t) :: Storage.t | nil
  def get_storage_from_hdd(hdd_id),
    do: StorageInternal.get_storage_from_hdd(hdd_id)
end
