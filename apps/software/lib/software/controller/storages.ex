defmodule HELM.Software.Controller.Storage do
  import Ecto.Query

  alias HELM.Software.Model.Repo
  alias HELM.Software.Model.Storage, as: MdlStorageDrive

  def create do
    MdlStorageDrive.create_changeset()
    |> Repo.insert()
  end

  def find(storage_id) do
    case Repo.get_by(MdlStorageDrive, storage_id: storage_id) do
      nil -> {:error, :notfound}
      res -> {:ok, res}
    end
  end

  def delete(storage_id) do
    case find(storage_id) do
      {:ok, storage} -> Repo.delete(storage)
      error -> error
    end
  end
end
