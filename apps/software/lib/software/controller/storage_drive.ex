defmodule HELM.Software.Controller.StorageDrive do

  alias HELM.Software.Repo
  alias HELM.Software.Model.StorageDrive, as: MdlStorageDrive
  import Ecto.Query, only: [where: 3]

  @spec create(%{}) :: {:ok, MdlStorageDrive.t} | {:error, Ecto.Changeset.t}
  def create(params) do
    params
    |> MdlStorageDrive.create_changeset()
    |> Repo.insert()
  end

  @spec find(HELL.PK.t, integer) :: {:ok, MdlStorageDrive.t} | {:error, :notfound}
  def find(storage_id, drive_id) do
    case Repo.get_by(MdlStorageDrive, storage_id: storage_id, drive_id: drive_id) do
      nil ->
        {:error, :notfound}
      drive ->
        {:ok, drive}
    end
  end

  @spec delete(HELL.PK.t, integer) :: no_return
  def delete(storage_id, drive_id) do
    MdlStorageDrive
    |> where([s], s.storage_id == ^storage_id)
    |> where([s], s.drive_id == ^drive_id)
    |> Repo.delete_all()

    :ok
  end
end