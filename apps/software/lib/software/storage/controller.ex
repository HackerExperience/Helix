defmodule HELM.Software.Storage.Controller do
  import Ecto.Query

  alias HELM.Software.Repo
  alias HELM.Software.Storage.Schema, as: SoftStorageSchema

  def create do
    SoftStorageSchema.create_changeset()
    |> Repo.insert()
  end

  def find(storage_id) do
    case Repo.get_by(SoftStorageSchema, storage_id: storage_id) do
      nil -> {:error, :notfound}
      res -> {:ok, res}
    end
  end

  def delete(storage_id) do
  alias HELM.Software.Storage.Schema, as: SoftStorageSchema
    case find(storage_id) do
      {:ok, storage} -> Repo.delete(storage)
      error -> error
    end
  end
end
