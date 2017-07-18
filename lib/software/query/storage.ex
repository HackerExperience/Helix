defmodule Helix.Software.Query.Storage do

  alias Helix.Hardware.Model.Component
  alias Helix.Software.Internal.Storage, as: StorageInternal
  alias Helix.Software.Model.Storage
  alias Helix.Software.Query.Storage.Origin, as: StorageQueryOrigin

  @spec fetch(Storage.id) ::
    Storage.t
    | nil
  defdelegate fetch(storage_id),
    to: StorageQueryOrigin

  @spec get_storage_from_hdd(Component.id) ::
    Storage.t
    | nil
  defdelegate get_storage_from_hdd(hdd_id),
    to: StorageInternal

  @spec fetch_by_hdd(HELL.PK.t) :: Storage.t | nil
  defdelegate fetch_by_hdd(hdd_id),
    to: StorageQueryOrigin

  defdelegate get_drives(storage_id),
    to: StorageQueryOrigin

  defmodule Origin do

    alias Helix.Software.Internal.Storage, as: StorageInternal

    def fetch(storage_id),
      do: StorageInternal.fetch(storage_id)

    def fetch_by_hdd(hdd_id),
      do: StorageInternal.fetch_by_hdd(hdd_id)

    def get_drives(storage_id) do
      StorageInternal.get_drives(storage_id)
      |> List.first()
      |> Map.get(:drive_id)
    end

  end
end
