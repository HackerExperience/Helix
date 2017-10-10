defmodule Helix.Software.Query.Storage do

  alias Helix.Hardware.Model.Component
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Storage
  alias Helix.Software.Internal.File, as: FileInternal
  alias Helix.Software.Internal.Storage, as: StorageInternal
  alias Helix.Software.Internal.StorageDrive, as: StorageDriveInternal

  @spec fetch(Storage.id) ::
    Storage.t
    | nil
  defdelegate fetch(storage_id),
    to: StorageInternal

  @spec fetch_by_hdd(Component.id) ::
    Storage.t
    | nil
  defdelegate fetch_by_hdd(hdd_id),
    to: StorageInternal

  @spec storage_contents(Storage.t) ::
    %{folder :: File.path => [File.t]}
  def storage_contents(storage) do
    storage
    |> FileInternal.get_files_on_storage()
    |> Enum.group_by(&(&1.path))
  end

  @spec files_on_storage(Storage.t) ::
    [File.t]
  defdelegate files_on_storage(storage),
    to: FileInternal,
    as: :get_files_on_storage

  @spec get_drive_ids(Storage.id) ::
    [Component.id]
  def get_drive_ids(storage_id) do
    storage_id
    |> StorageInternal.get_drives()
    |> Enum.map(&(&1.drive_id))
  end

  @spec get_storage_drives(Storage.t) ::
    [Component.id]
  defdelegate get_storage_drives(storage),
    to: StorageDriveInternal
end
