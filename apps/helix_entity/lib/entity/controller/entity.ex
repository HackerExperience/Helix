defmodule Helix.Entity.Controller.Entity do

  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Model.EntityServer
  alias Helix.Entity.Model.EntityComponent
  alias Helix.Entity.Repo

  import Ecto.Query, only: [where: 3]

  @spec create(Entity.creation_params) :: {:ok, Entity.t} | no_return
  def create(params) do
    params
    |> Entity.create_changeset()
    |> Repo.insert()
  end

  @spec find(Entity.id) :: {:ok, Entity.t} | {:error, :notfound}
  def find(entity_id) do
    case Repo.get_by(Entity, entity_id: entity_id) do
      nil ->
        {:error, :notfound}
      entity ->
        {:ok, entity}
    end
  end

  @spec delete(Entity.t | Entity.id) :: no_return
  def delete(entity = %Entity{}),
    do: delete(entity.entity_id)
  def delete(entity_id) do
    Entity
    |> where([s], s.entity_id == ^entity_id)
    |> Repo.delete_all()

    :ok
  end

  @spec link_component(Entity.t, HELL.PK.t) :: :ok | {:error, Ecto.Changeset.t}
  def link_component(%Entity{entity_id: id}, component) do
    params = %{entity_id: id, component_id: component}
    changeset = EntityComponent.create_changeset(params)

    Repo.insert(changeset)
  end

  @spec unlink_component(HELL.PK.t) :: :ok
  def unlink_component(component) do
    component
    |> EntityComponent.Query.by_component_id()
    |> Repo.delete_all()

    :ok
  end

  @spec link_server(Entity.t, HELL.PK.t) :: :ok | {:error, Ecto.Changeset.t}
  def link_server(%Entity{entity_id: id}, server) do
    params = %{entity_id: id, server_id: server}
    changeset = EntityServer.create_changeset(params)

    Repo.insert(changeset)
  end

  @spec unlink_server(HELL.PK.t) :: :ok
  def unlink_server(server) do
    server
    |> EntityServer.Query.by_server_id()
    |> Repo.delete_all()

    :ok
  end
end
