defmodule HELM.Entity.Controller.EntityTypes do
  import Ecto.Query

  alias HELF.{Broker, Error}
  alias HELM.Entity.Model.Repo
  alias HELM.Entity.Model.EntityTypes, as: MdlEntityTypes

  def create(type_name) do
    %{entity_type: type_name}
    |> MdlEntityTypes.create_changeset()
    |> Repo.insert()
  end

  def find(type_name) do
    case Repo.get_by(MdlEntityTypes, entity_type: type_name) do
      nil -> {:error, :notfound}
      entity_type -> {:ok, entity_type}
    end
  end

  def delete(entity_type) do
    MdlEntityTypes
    |> where([s], s.entity_type == ^entity_type)
    |> Repo.delete_all()

    :ok
  end
end