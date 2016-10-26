defmodule HELM.Software.Storage.Drive.Controller do
  import Ecto.Query

  alias HELM.Software.Repo
  alias HELM.Software.Storage.Drive.Schema, as: StorageDriveSchema

  def create(drive_id, storage_id) do
    %{drive_id: drive_id, storage_id: storage_id}
    |> StorageDriveSchema.create_changeset()
    |> Repo.insert()
  end

  def find(drive_id) do
    case Repo.get_by(StorageDriveSchema, drive_id: drive_id) do
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
