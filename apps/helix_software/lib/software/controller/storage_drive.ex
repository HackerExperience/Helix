defmodule Helix.Software.Controller.StorageDrive do

  alias Helix.Software.Model.Storage
  alias Helix.Software.Model.StorageDrive
  alias Helix.Software.Repo

  @type find_params :: [find_param]
  @type find_param :: {:storage, Storage.t | Storage.id}

  @spec create(StorageDrive.creation_params) ::
    {:ok, StorageDrive.t}
    | {:error, Ecto.Changeset.t}
  def create(params) do
    params
    |> StorageDrive.create_changeset()
    |> Repo.insert()
  end

  @spec find(find_params) :: [StorageDrive.t]
  def find(params) do
    params
    |> Enum.reduce(StorageDrive, &reduce_find_params/2)
    |> Repo.all()
  end

  @spec reduce_find_params(find_param, Ecto.Queryable.t) :: Ecto.Queryable.t
  defp reduce_find_params({:storage, storage}, query),
    do: StorageDrive.Query.from_storage(query, storage)

  @spec delete(Storage.t | HELL.PK.t, integer) :: no_return
  def delete(storage, drive_id) do
    storage
    |> StorageDrive.Query.from_storage()
    |> StorageDrive.Query.by_drive_id(drive_id)
    |> Repo.delete_all()

    :ok
  end
end