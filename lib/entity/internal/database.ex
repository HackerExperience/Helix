defmodule Helix.Entity.Internal.Database do

  import Ecto.Query, only: [select: 2, select: 3, limit: 2]

  alias HELL.IPv4
  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Server
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Model.Database
  alias Helix.Entity.Repo

  @select_fields ~w/
    network_id
    server_ip
    server_type
    password
    alias
    notes
    inserted_at
    updated_at/a

  @spec get_database(Entity.t | Entity.id) ::
    [map]
  def get_database(entity) do
    entity
    |> Database.Query.by_entity()
    |> select_for_presentation()
    |> Database.Query.order_by_newest_on_network()
    |> Repo.all()
  end

  @spec get_entry(Entity.t | Entity.id, Network.t | Network.id, IPv4.t) ::
    Database.t
    | nil
  def get_entry(entity, network, ip) do
    entity
    |> Database.Query.by_entity()
    |> Database.Query.by_network(network)
    |> Database.Query.by_ip(ip)
    |> Repo.one()
  end

  @spec get_server_entries(Entity.t | Entity.id, Server.t | Server.id) ::
    [Database.t]
  def get_server_entries(entity, server) do
    entity
    |> Database.Query.by_entity()
    |> Database.Query.by_server(server)
    |> Repo.all()
  end

  @spec get_server_password(Entity.t | Entity.id, Server.t | Server.id) ::
    String.t
    | nil
  def get_server_password(entity, server) do
    entity
    |> Database.Query.by_entity()
    |> Database.Query.by_server(server)
    |> select([d], d.password)
    |> limit(1)
    |> Repo.all()
  end

  @spec create(Entity.t | Entity.id, Network.t | Network.id, IPv4.t, Server.t | Server.id, String.t) ::
    {:ok, Database.t}
    | {:error, Ecto.Changeset.t}
  def create(entity, network, ip, server, server_type) do
    changeset = Database.create(entity, network, ip, server, server_type)

    Repo.insert(changeset, on_conflict: :nothing)
  end

  @spec update(Database.t, map) ::
    {:ok, Database.t}
    | {:error, Ecto.Changeset.t}
  def update(entry, params) do
    entry
    |> Database.update(params)
    |> Repo.update()
  end

  @spec delete_server_from_network(Server.t | Server.id, Network.t | Network.id) ::
    :ok
  def delete_server_from_network(server, network) do
    server
    |> Database.Query.by_server(server)
    |> Database.Query.by_network(network)
    |> Repo.delete_all()

    :ok
  end

  @spec delete_server(Server.t | Server.id) ::
    :ok
  def delete_server(server) do
    server
    |> Database.Query.by_server(server)
    |> Repo.delete_all()

    :ok
  end

  # I think this doesn't belongs here
  @spec select_for_presentation(Ecto.Queryable.t) ::
    Ecto.Queryable.t
  def select_for_presentation(query),
    do: select(query, ^@select_fields)
end
