defmodule HELM.Software.Controller.StorageDrives do
  import Ecto.Query

  alias HELM.Software.Model.Repo
  alias HELM.Software.Model.StorageDrives, as: MdlStorageDrives

  def create(drive_id, storage_id) do
    %{drive_id: drive_id, storage_id: storage_id}
    |> MdlStorageDrives.create_changeset()
    |> Repo.insert()
  end

  def find(drive_id) do
    case Repo.get_by(MdlStorageDrives, drive_id: drive_id) do
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
