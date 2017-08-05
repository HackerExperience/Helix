defmodule Helix.Entity.Query.Database do

  alias HELL.IPv4
  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Server
  alias Helix.Entity.Internal.Database, as: DatabaseInternal
  alias Helix.Entity.Model.Database
  alias Helix.Entity.Model.Entity

  @spec get_database(Entity.t) ::
    [map]
  # TODO: documentation
  defdelegate get_database(entity),
    to: DatabaseInternal

  @spec get_entry(Entity.t, Network.t | Network.id, IPv4.t) ::
    Database.t
    | nil
  defdelegate get_entry(entity, network, ip),
    to: DatabaseInternal

  @spec get_server_password(Entity.t, Server.t | Server.id) ::
    map
    | nil
  # TODO: documentation
  defdelegate get_server_password(entity, server),
    to: DatabaseInternal

  @spec get_server_entries(Entity.t, Server.t | Server.id) ::
    [Database.t]
  defdelegate get_server_entries(entity, server),
    to: DatabaseInternal
end
