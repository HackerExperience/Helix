defmodule Helix.Entity.Controller.EntityComponent do

  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Model.EntityComponent
  alias Helix.Entity.Repo

  import Ecto.Query, only: [select: 3]

  @spec create(Entity.t | Entity.id, HELL.PK.t) ::
    {:ok, EntityComponent.t}
    | {:error, Ecto.Changeset.t}
  def create(entity = %Entity{}, component_id),
    do: create(entity.entity_id, component_id)
  def create(entity_id, component_id) do
    %{entity_id: entity_id, component_id: component_id}
    |> EntityComponent.create_changeset()
    |> Repo.insert()
  end

  @spec find(Entity.t | Entity.id) :: [HELL.PK.t]
  def find(entity) do
    entity
    |> EntityComponent.Query.from_entity()
    |> select([ec], ec.component_id)
    |> Repo.all()
  end

  @spec delete(Entity.t | Entity.id, HELL.PK.t) :: no_return
  def delete(entity, component_id) do
    entity
    |> EntityComponent.Query.from_entity()
    |> EntityComponent.Query.by_component_id(component_id)
    |> Repo.delete_all()

    :ok
  end
end