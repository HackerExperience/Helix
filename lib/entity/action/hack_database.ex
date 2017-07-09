defmodule Helix.Entity.Action.HackDatabase do

  alias HELL.IPv4
  alias Helix.Server.Model.Server
  alias Helix.Network.Model.Network
  alias Helix.Entity.Internal.HackDatabase, as: HackDatabaseInternal
  alias Helix.Entity.Model.HackDatabase
  alias Helix.Entity.Repo

  @spec create(Entity.t, Network.id, IPv4.t, Server.id, String.t) ::
    {:ok, %{{:hack_database, :new} => HackDatabase.t}}
    | {:error, {:hack_database, :new}, term, map}
  def create(entity, network_id, ip, server_id, server_type) do
    entity
    |> HackDatabaseInternal.create(network_id, ip, server_id, server_type)
    |> Repo.transaction()
  end

  @spec update(Entity.t, Network.id, IPv4.t, map) ::
    {:ok, %{{:hack_database, :updated} => HackDatabase.t}}
    | {:error, {:hack_database, :updated}, term, map}
  def update(entity, network_id, ip, params) do
    entity
    |> HackDatabaseInternal.get_entry(network_id, ip)
    |> Repo.one()
    |> HackDatabaseInternal.update(params)
    |> Repo.transaction()
  end

  @spec delete_server_from_network(Server.id, Network.id) ::
    {:ok, %{{:hack_database, :deleted} => term}}
    | {:error, {:hack_database, :deleted}, term, map}
  def delete_server_from_network(server_id, network_id) do
    server_id
    |> HackDatabaseInternal.delete_server_from_network(network_id)
    |> Repo.transaction()
  end

  @spec delete_server(Server.id) ::
    {:ok, %{{:hack_database, :deleted} => term}}
    | {:error, {:hack_database, :deleted}, term, map}
  def delete_server(server_id) do
    server_id
    |> HackDatabaseInternal.delete_server()
    |> Repo.transaction()
  end
end
