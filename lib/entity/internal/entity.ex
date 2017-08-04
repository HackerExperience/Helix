defmodule Helix.Entity.Internal.Entity do

  alias Helix.Cache.Action.Cache, as: CacheAction
  alias Helix.Hardware.Model.Component
  alias Helix.Server.Model.Server
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Model.EntityComponent
  alias Helix.Entity.Model.EntityServer
  alias Helix.Entity.Repo

  @spec fetch(Entity.id) ::
    Entity.t
    | nil
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

  @spec fetch_by_server(Server.idt) ::
    Entity.t
    | nil
  @doc """
  Fetches the entity that owns `server`

  Returns nil if server is not owned

  ## Examples

  iex> fetch_by_server("10::478F:8BF:D47B:D04E:8190")
  %Entity{}

  iex> fetch_by_server("aa:bbbb::ccc")
  nil
  """
  def fetch_by_server(server) do
    server
    |> Entity.Query.owns_server()
    |> Repo.one()
  end

  @spec get_servers(Entity.t) ::
    [EntityServer.t]
  @doc """
  Returns a list of servers that belong to a given entity.
  """
  def get_servers(entity) do
    entity
    |> EntityServer.Query.by_entity()
    |> Repo.all()
    |> Enum.map(&(&1.server_id))
  end

  @spec create(Entity.creation_params) ::
    {:ok, Entity.t}
    | {:error, Ecto.Changeset.t}
  def create(params) do
    params
    |> Entity.create_changeset()
    |> Repo.insert()
  end

  @spec link_component(Entity.t, Component.idt) ::
    {:ok, any}
    | {:error, Ecto.Changeset.t}
  def link_component(entity, component_id) do
    %{entity_id: entity, component_id: component_id}
    |> EntityComponent.create_changeset()
    |> Repo.insert()
  end

  @spec unlink_component(Component.idt) ::
    :ok
  def unlink_component(component) do
    component
    |> EntityComponent.Query.by_component()
    |> Repo.delete_all()

    :ok
  end

  @spec link_server(Entity.t, Server.idt) ::
    {:ok, EntityServer.t}
    | {:error, Ecto.Changeset.t}
  def link_server(entity, server_id) do
    %{entity_id: entity, server_id: server_id}
    |> EntityServer.create_changeset()
    |> Repo.insert()
  end

  @spec unlink_server(Server.idt) ::
    :ok
  def unlink_server(server) do
    server
    |> EntityServer.Query.by_server()
    |> Repo.delete_all()

    CacheAction.purge_server(server)

    :ok
  end

  @spec delete(Entity.t) ::
    :ok
  def delete(entity) do
    servers = get_servers(entity)

    Repo.delete(entity)

    Enum.each(servers, &CacheAction.purge_server(&1))

    :ok
  end
end
