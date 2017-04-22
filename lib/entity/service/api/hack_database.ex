defmodule Helix.Entity.Service.API.HackDatabase do

  alias HELL.PK
  alias HELL.IPv4
  alias Helix.Entity.Controller.HackDatabase, as: HackDatabaseController
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Model.HackDatabase
  alias Helix.Entity.Repo

  def get_database(entity) do
    entity
    |> HackDatabaseController.get_database()
    |> Repo.all()
  end

  @spec create(Entity.t, PK.t, IPv4.t, PK.t, String.t) ::
    {:ok, %{{:hack_database, :new} => HackDatabase.t}}
    | {:error, {:hack_database, :new}, term, map}
  def create(entity, network_id, ip, server_id, server_type) do
    entity
    |> HackDatabaseController.create(network_id, ip, server_id, server_type)
    |> Repo.transaction()
  end

  @spec update(Entity.t, PK.t, IPv4.t, map) ::
    {:ok, %{{:hack_database, :updated} => HackDatabase.t}}
    | {:error, {:hack_database, :updated}, term, map}
  def update(entity, network_id, ip, params) do
    entity
    |> HackDatabaseController.get_entry(network_id, ip)
    |> Repo.one()
    |> HackDatabaseController.update(params)
    |> Repo.transaction()
  end

  @spec delete_server_from_network(PK.t, PK.t) ::
    {:ok, %{{:hack_database, :deleted} => term}}
    | {:error, {:hack_database, :deleted}, term, map}
  def delete_server_from_network(server_id, network_id) do
    server_id
    |> HackDatabaseController.delete_server_from_network(network_id)
    |> Repo.transaction()
  end

  @spec delete_server(PK.t) ::
    {:ok, %{{:hack_database, :deleted} => term}}
    | {:error, {:hack_database, :deleted}, term, map}
  def delete_server(server_id) do
    server_id
    |> HackDatabaseController.delete_server()
    |> Repo.transaction()
  end
end
