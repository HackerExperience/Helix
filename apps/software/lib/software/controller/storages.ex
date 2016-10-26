defmodule HELM.Software.Controller.Storages do
  import Ecto.Query

  alias HELM.Software.Model.Repo
  alias HELM.Software.Model.Storages, as: MdlStorages

  def create do
    MdlStorages.create_changeset()
    |> Repo.insert()
  end

  def find(storage_id) do
    case Repo.get_by(MdlStorages, storage_id: storage_id) do
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
