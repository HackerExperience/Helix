defmodule Helix.Entity.Controller.EntityComponent do

  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Model.EntityComponent
  alias Helix.Entity.Repo

  import Ecto.Query, only: [where: 3]

  @spec create(Entity.id, HELL.PK.t) ::
    {:ok, EntityComponent.t}
    | {:error, Ecto.Changeset.t}
  def create(entity_id, component_id) do
    %{entity_id: entity_id, component_id: component_id}
    |> EntityComponent.create_changeset()
    |> Repo.insert()
  end

  @spec find(Entity.id) :: [EntityComponent.t]
  def find(entity_id) do
    EntityComponent
    |> where([s], s.entity_id == ^entity_id)
    |> Repo.all()
  end

  @spec delete(Entity.id, HELL.PK.t) :: no_return
  def delete(entity_id, component_id) do
    EntityComponent
    |> where([s], s.entity_id == ^entity_id)
    |> where([s], s.component_id == ^component_id)
    |> Repo.delete_all()

    :ok
  end
end