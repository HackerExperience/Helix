defmodule HELM.Software.Controller.Storage do
  import Ecto.Query

  alias HELM.Software.Repo
  alias HELM.Software.Model.Storage, as: MdlStorage

  def create do
    MdlStorage.create_changeset()
    |> Repo.insert()
  end

  def find(storage_id) do
    case Repo.get_by(MdlStorage, storage_id: storage_id) do
      nil -> {:error, :notfound}
      res -> {:ok, res}
    end
  end

  def delete(storage_id) do
    MdlStorage
    |> where([s], s.storage_id == ^storage_id)
    |> Repo.delete_all()

    :ok
  end
end