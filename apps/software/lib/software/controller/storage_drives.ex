defmodule HELM.Software.Controller.StorageDrive do
  import Ecto.Query

  alias HELM.Software.Model.Repo
  alias HELM.Software.Model.StorageDrive, as: MdlStorageDrive

  def create(drive_id, storage_id) do
    %{drive_id: drive_id, storage_id: storage_id}
    |> MdlStorageDrive.create_changeset()
    |> Repo.insert()
  end

  def find(drive_id) do
    case Repo.get_by(MdlStorageDrive, drive_id: drive_id) do
      nil -> {:error, :notfound}
      res -> {:ok, res}
    end
  end

  def delete(drive_id) do
    case find(drive_id) do
      {:ok, drive} -> Repo.delete(drive)
      error -> error
    end
  end
end
