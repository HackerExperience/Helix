defmodule Helix.Software.Query.Storage do

  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Server.Model.Component
  alias Helix.Server.Model.Server
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

  @spec get_main_storage(Server.idt) ::
    Storage.t
  @doc """
  Returns the "main" storage of a server, which, for the time being, is the only
  storage a server may have.
  """
  def get_main_storage(server) do
    server
    |> get_main_storage_id()
    |> fetch()
  end

  @spec get_main_storage_id(Server.idt) ::
    Storage.id
  @doc """
  Identical to `get_main_storage`, but only returns the server's storage id.
  """
  def get_main_storage_id(server = %Server{}),
    do: get_main_storage_id(server.server_id)
  def get_main_storage_id(server_id = %Server.ID{}) do
    server_id
    |> CacheQuery.from_server_get_storages!()
    |> List.first()
  end
end
