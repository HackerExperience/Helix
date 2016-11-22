defmodule HELM.Software.Controller.Storage do

  alias HELM.Software.Repo
  alias HELM.Software.Model.Storage, as: MdlStorage
  import Ecto.Query, only: [where: 3]

  @spec create() :: {:ok, MdlStorage.t} | {:error, Ecto.Changeset.t}
  def create do
    MdlStorage.create_changeset()
    |> Repo.insert()
  end

  @spec find(HELL.PK.t) :: {:ok, MdlStorage.t} | {:error, :notfound}
  def find(storage_id) do
    case Repo.get_by(MdlStorage, storage_id: storage_id) do
      nil ->
        {:error, :notfound}
      res ->
        {:ok, res}
    end
  end

  @spec delete(HELL.PK.t) :: no_return
  def delete(storage_id) do
    MdlStorage
    |> where([s], s.storage_id == ^storage_id)
    |> Repo.delete_all()

    :ok
  end
end