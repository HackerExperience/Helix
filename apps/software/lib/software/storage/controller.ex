defmodule HELM.Software.Storage.Controller do
  import Ecto.Query

  alias HELM.Software.Repo
  alias HELM.Software.Storage.Schema, as: SoftStorageSchema

  def create do
    SoftStorageSchema.create_changeset()
    |> do_create
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
      {:ok, storage} -> do_delete(storage)
      error -> error
    end
  end

  defp do_create(changeset) do
    Repo.insert(changeset)
  end

  defp do_delete(changeset) do
    Repo.delete(changeset)
  end
end
