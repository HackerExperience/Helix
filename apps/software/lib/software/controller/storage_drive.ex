defmodule Helix.Software.Controller.StorageDrive do

  alias Helix.Software.Repo
  alias Helix.Software.Model.StorageDrive
  import Ecto.Query, only: [where: 3]

  @spec create(%{}) :: {:ok, StorageDrive.t} | {:error, Ecto.Changeset.t}
  def create(params) do
    params
    |> StorageDrive.create_changeset()
    |> Repo.insert()
  end

  @spec find(HELL.PK.t, integer) :: {:ok, StorageDrive.t} | {:error, :notfound}
  def find(storage_id, drive_id) do
    query = [storage_id: storage_id, drive_id: drive_id]
    case Repo.get_by(StorageDrive, query) do
      nil ->
        {:error, :notfound}
      drive ->
        {:ok, drive}
    end
  end

  @spec delete(HELL.PK.t, integer) :: no_return
  def delete(storage_id, drive_id) do
    StorageDrive
    |> where([s], s.storage_id == ^storage_id)
    |> where([s], s.drive_id == ^drive_id)
    |> Repo.delete_all()

    :ok
  end
end