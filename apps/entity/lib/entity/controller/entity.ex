defmodule HELM.Entity.Controller.Entity do
  import Ecto.Query

  alias HELF.Broker
  alias HELM.Entity.Model.Entity, as: MdlEntity
  alias HELM.Entity.Repo

  def create(params) do
    params
    |> MdlEntity.create_changeset()
    |> Repo.insert()
  end

  def find(entity_id) do
    case Repo.get_by(MdlEntity, entity_id: entity_id) do
      nil -> {:error, :notfound}
      entity -> {:ok, entity}
    end
  end

  def delete(entity_id) do
    MdlEntity
    |> where([s], s.entity_id == ^entity_id)
    |> Repo.delete_all()

    :ok
  end
end