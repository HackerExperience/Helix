defmodule Helix.Software.Controller.Storage do

  alias Helix.Software.Model.Storage
  alias Helix.Software.Model.StorageDrive
  alias Helix.Software.Repo

  import Ecto.Query, only: [join: 5, where: 3]

  @spec create() :: {:ok, Storage.t} | {:error, Ecto.Changeset.t}
  def create do
    Storage.create_changeset()
    |> Repo.insert()
  end

  @spec fetch(HELL.PK.t) :: Storage.t | nil
  def fetch(storage_id),
    do: Repo.get(Storage, storage_id)

  @spec delete(HELL.PK.t) :: no_return
  def delete(storage_id) do
    Storage
    |> where([s], s.storage_id == ^storage_id)
    |> Repo.delete_all()

    :ok
  end

  @spec get_storage_from_hdd(HELL.PK.t) :: Storage.t | nil
  def get_storage_from_hdd(hdd_id) do
    Storage
    |> join(:inner, [s], sd in StorageDrive, s.storage_id == sd.storage_id)
    |> where([s, sd], sd.drive_id == ^hdd_id)
    |> Repo.one()
  end
end
