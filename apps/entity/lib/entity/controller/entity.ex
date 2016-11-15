defmodule HELM.Entity.Controller.Entity do
  import Ecto.Query

  alias Ecto.Changeset
  alias HELM.Entity.Model.Entity, as: MdlEntity
  alias HELM.Entity.Repo

  @spec create(params :: MdlEntity.create_params) :: {:ok, MdlEntity.t} | {:error, Changeset.t}
  def create(params) do
    params
    |> MdlEntity.create_changeset()
    |> Repo.insert()
  end

  @spec find(entity_id :: MdlEntity.entity_id) :: {:ok, MdlEntity.t} | {:error, :notfound}
  def find(entity_id) do
    case Repo.get_by(MdlEntity, entity_id: entity_id) do
      nil -> {:error, :notfound}
      entity -> {:ok, entity}
    end
  end

  @spec delete(entity_id :: MdlEntity.entity_id) :: :ok
  def delete(entity_id) do
    MdlEntity
    |> where([s], s.entity_id == ^entity_id)
    |> Repo.delete_all()

    :ok
  end
end