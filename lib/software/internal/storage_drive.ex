defmodule Helix.Software.Internal.StorageDrive do

  alias Helix.Cache.Action.Cache, as: CacheAction
  alias Helix.Server.Model.Component
  alias Helix.Software.Internal.Storage, as: StorageInternal
  alias Helix.Software.Model.Storage
  alias Helix.Software.Model.StorageDrive
  alias Helix.Software.Repo

  @spec get_storage_drives(Storage.t) ::
    [Component.id]
  def get_storage_drives(storage) do
    storage
    |> StorageDrive.Query.by_storage()
    |> StorageDrive.Query.select_drive_id()
    |> Repo.all()
  end

  @spec link_drive(Storage.t, Component.idt) ::
    :ok
    | {:error, :internal}
  def link_drive(storage, drive) do
    result =
      %{storage_id: storage.storage_id, drive_id: drive}
      |> StorageDrive.create_changeset()
      |> Repo.insert()

    case result do
      {:ok, _} ->
        CacheAction.update_server_by_storage(storage.storage_id)

        :ok
      {:error, _} ->
        # TODO: check if the problem is an unique constraint violation and
        # return an error like :already_in_use instead
        {:error, :internal}
    end
  end

  @spec unlink_drive(Component.idt) ::
    :ok
  def unlink_drive(drive) do
    # TODO: Check if storage is over HDD storage limits and prune files (and
    #   storage) if necessary
    storage = StorageInternal.fetch_by_hdd(drive)

    drive
    |> StorageDrive.Query.by_drive()
    |> Repo.delete_all()

    if storage do
      CacheAction.purge_storage(storage)
      CacheAction.update_server_by_storage(storage)
    end

    :ok
  end
end
