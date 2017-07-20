defmodule Helix.Software.Internal.Storage do

  import Ecto.Query, only: [join: 5, where: 3]

  alias Helix.Hardware.Model.Component
  alias Helix.Software.Model.Storage
  alias Helix.Software.Model.StorageDrive
  alias Helix.Software.Repo

  @spec create() ::
    {:ok, Storage.t}
    | {:error, Ecto.Changeset.t}
  def create do
    Storage.create_changeset()
    |> Repo.insert()
  end

  @spec fetch(Storage.id) ::
    Storage.t
    | nil
  def fetch(storage_id),
    do: Repo.get(Storage, storage_id)

  @spec delete(Storage.id) ::
    :ok
  def delete(storage_id) do
    Storage
    |> where([s], s.storage_id == ^storage_id)
    |> Repo.delete_all()

    :ok
  end

  # FIXME: This doesn't belongs here, does it ?
  @spec get_storage_from_hdd(Component.id) ::
    Storage.t
    | nil
  def get_storage_from_hdd(hdd_id) do
    Storage
    |> join(:inner, [s], sd in StorageDrive, s.storage_id == sd.storage_id)
    |> where([s, sd], sd.drive_id == ^hdd_id)
    |> Repo.one()
  end
end
