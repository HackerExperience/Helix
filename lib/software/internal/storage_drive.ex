defmodule Helix.Software.Internal.StorageDrive do

  import Ecto.Query, only: [select: 3]

  alias Helix.Cache.Action.Cache, as: CacheAction
  alias Helix.Hardware.Model.Component
  alias Helix.Software.Internal.Storage, as: StorageInternal
  alias Helix.Software.Model.Storage
  alias Helix.Software.Model.StorageDrive
  alias Helix.Software.Repo

  @spec get_storage_drives(Storage.t) ::
    [Component.id]
  def get_storage_drives(storage) do
    storage
    |> StorageDrive.Query.from_storage()
    |> select([sd], sd.drive_id)
    |> Repo.all()
  end

  @spec link_drive(Storage.t, Component.id) ::
    :ok
    | {:error, reason :: term}
  def link_drive(storage, drive_id) do
    result =
      %{storage_id: storage.storage_id, drive_id: drive_id}
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

  @spec unlink_drive(Component.id) ::
    :ok
  def unlink_drive(drive_id) do

    storage = StorageInternal.fetch_by_hdd(drive_id)

    drive_id
      |> StorageDrive.Query.by_drive_id()
      |> Repo.delete_all()

    CacheAction.purge_storage(storage)
    CacheAction.update_server_by_storage(storage)

    :ok
  end
end
