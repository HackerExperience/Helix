defmodule HELM.Software.Controller.StorageDrive do
  import Ecto.Query

  alias HELM.Software.Model.Repo
  alias HELM.Software.Model.StorageDrive, as: MdlStorageDrive

  def create(params) do
    params
    |> MdlStorageDrive.create_changeset()
    |> Repo.insert()
  end

  def find(storage_id, drive_id) do
    case Repo.get_by(MdlStorageDrive, storage_id: storage_id, drive_id: drive_id) do
      nil -> {:error, :notfound}
      drive -> {:ok, drive}
    end
  end

  def delete(storage_id, drive_id) do
    MdlStorageDrive
    |> where([s], s.storage_id == ^storage_id and s.drive_id == ^drive_id)
    |> Repo.delete_all()

    :ok
  end
end