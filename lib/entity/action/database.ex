defmodule Helix.Entity.Action.Database do

  alias HELL.IPv4
  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Server
  alias Helix.Entity.Internal.Database, as: DatabaseInternal
  alias Helix.Entity.Model.Database
  alias Helix.Entity.Repo

  @spec create(Entity.t, Network.id, IPv4.t, Server.id, String.t) ::
    {:ok, %{{:database, :new} => Database.t}}
    | {:error, {:database, :new}, term, map}
  def create(entity, network_id, ip, server_id, server_type) do
    entity
    |> DatabaseInternal.create(network_id, ip, server_id, server_type)
    |> Repo.transaction()
  end

  @spec update(Entity.t, Network.id, IPv4.t, map) ::
    {:ok, %{{:database, :updated} => Database.t}}
    | {:error, {:database, :updated}, term, map}
  def update(entity, network_id, ip, params) do
    entity
    |> DatabaseInternal.get_entry(network_id, ip)
    |> Repo.one()
    |> DatabaseInternal.update(params)
    |> Repo.transaction()
  end

  @spec delete_server_from_network(Server.id, Network.id) ::
    {:ok, %{{:database, :deleted} => term}}
    | {:error, {:database, :deleted}, term, map}
  def delete_server_from_network(server_id, network_id) do
    server_id
    |> DatabaseInternal.delete_server_from_network(network_id)
    |> Repo.transaction()
  end

  @spec delete_server(Server.id) ::
    {:ok, %{{:database, :deleted} => term}}
    | {:error, {:database, :deleted}, term, map}
  def delete_server(server_id) do
    server_id
    |> DatabaseInternal.delete_server()
    |> Repo.transaction()
  end
end
