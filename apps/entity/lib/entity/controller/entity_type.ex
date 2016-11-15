defmodule HELM.Entity.Controller.EntityType do
  import Ecto.Query

  alias Ecto.Changeset
  alias HELM.Entity.Repo
  alias HELM.Entity.Model.EntityType, as: MdlEntityType

  @spec create(type_name :: MdlEntityType.entity_type) :: {:ok, MdlEntityType.t} | {:error, Changeset.t}
  def create(type_name) do
    %{entity_type: type_name}
    |> MdlEntityType.create_changeset()
    |> Repo.insert()
  end

  @spec find(type_name :: MdlEntityType.entity_type) :: {:ok, MdlEntityType.t} | {:error, :notfound}
  def find(type_name) do
    case Repo.get_by(MdlEntityType, entity_type: type_name) do
      nil -> {:error, :notfound}
      entity_type -> {:ok, entity_type}
    end
  end

  @spec delete(entity_type :: MdlEntityType.entity_type) :: :ok
  def delete(entity_type) do
    MdlEntityType
    |> where([s], s.entity_type == ^entity_type)
    |> Repo.delete_all()

    :ok
  end
end