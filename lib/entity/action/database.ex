defmodule Helix.Entity.Action.Database do

  alias HELL.IPv4
  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Server
  alias Helix.Entity.Internal.Database, as: DatabaseInternal
  alias Helix.Entity.Model.Database
  alias Helix.Entity.Model.Entity

  @spec create(Entity.t, Network.t | Network.id, IPv4.t, Server.t | Server.id, String.t) ::
    {:ok, Database.t}
    | {:error, Ecto.Changeset.t}
  defdelegate create(entity, network, ip, server, server_type),
    to: DatabaseInternal

  @spec update(Database.t, map) ::
    {:ok, Database.t}
    | {:error, Ecto.Changeset.t}
  defdelegate update(entry, params),
    to: DatabaseInternal

  @spec delete_server_from_network(Server.t | Server.id, Network.t | Network.id) ::
    :ok
  defdelegate delete_server_from_network(server, network),
    to: DatabaseInternal

  @spec delete_server(Server.t | Server.id) ::
    :ok
  defdelegate delete_server(server),
    to: DatabaseInternal
end
