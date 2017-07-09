defmodule Helix.Entity.Internal.Entity do

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

  @spec fetch(Entity.id) :: Entity.t | nil
  @doc """
  Fetches the entity

  ## Examples

      iex> fetch("1::3F23:6EB2:72C6:426C:588E")
      %Entity{}

      iex> fetch("1::fff")
      nil
  """
  def fetch(id),
    do: Repo.get(Entity, id)

  @spec fetch_servers(Entity.t | Entity.id) :: EntityServer.t | nil
  def fetch_servers(entity = %Entity{}),
    do: fetch_servers(entity.entity_id)
  def fetch_servers(entity) do
    entity
    |> EntityServer.Query.from_entity2()
    |> Repo.all
  end

  @spec fetch_server_owner(HELL.PK.t) :: Entity.t | nil
  @doc """
  Fetches the entity that owns `server`

  Returns nil if server is not owned

  ## Examples

      iex> fetch_server_owner("10::478F:8BF:D47B:D04E:8190")
      %Entity{}

      iex> fetch_server_owner("aa:bbbb::ccc")
      nil
  """
  def fetch_server_owner(server) do
    with \
      es = %EntityServer{} <- Repo.get_by(EntityServer, server_id: server),
      %EntityServer{entity: entity = %Entity{}} <- Repo.preload(es, :entity)
    do
      entity
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

  @spec link_component(Entity.t, HELL.PK.t) ::
    {:ok, any}
    | {:error, Ecto.Changeset.t}
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

  @spec link_server(Entity.t, HELL.PK.t) ::
    {:ok, term}
    | {:error, Ecto.Changeset.t}
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
