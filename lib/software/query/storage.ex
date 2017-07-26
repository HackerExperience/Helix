defmodule Helix.Software.Query.Storage do

  alias Helix.Hardware.Model.Component
  alias Helix.Software.Model.Storage
  alias Helix.Software.Query.Storage.Origin, as: StorageQueryOrigin

  @spec fetch(Storage.id) ::
    Storage.t
    | nil
  defdelegate fetch(storage_id),
    to: StorageQueryOrigin

  @spec fetch_by_hdd(Component.id) ::
    Storage.t
    | nil
  defdelegate fetch_by_hdd(hdd_id),
    to: StorageQueryOrigin

  @spec get_drive_ids(Storage.id) ::
    [Component.id]
  defdelegate get_drive_ids(storage_id),
    to: StorageQueryOrigin

  defmodule Origin do

    alias Helix.Software.Internal.Storage, as: StorageInternal

    def fetch(storage_id),
      do: StorageInternal.fetch(storage_id)

    def fetch_by_hdd(hdd_id),
      do: StorageInternal.fetch_by_hdd(hdd_id)

    def get_drive_ids(storage_id) do
      storage_id
      |> StorageInternal.get_drives()
      |> Enum.map(&(&1.drive_id))
    end
  end
end
