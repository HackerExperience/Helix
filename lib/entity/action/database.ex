defmodule Helix.Entity.Action.Database do

  alias HELL.IPv4
  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Server
  alias Helix.Entity.Internal.Database, as: DatabaseInternal
  alias Helix.Entity.Model.Database
  alias Helix.Entity.Model.Entity

  @spec create(Entity.t, Network.idt, IPv4.t, Server.idt, String.t) ::
    {:ok, Database.t}
    | {:error, Ecto.Changeset.t}
  defdelegate create(entity, network, ip, server, server_type),
    to: DatabaseInternal

  @spec update(Database.t, map) ::
    {:ok, Database.t}
    | {:error, Ecto.Changeset.t}
  defdelegate update(entry, params),
    to: DatabaseInternal

  @spec delete_server_from_network(Server.idt, Network.idt) ::
    :ok
  defdelegate delete_server_from_network(server, network),
    to: DatabaseInternal

  @spec delete_server(Server.idt) ::
    :ok
  defdelegate delete_server(server),
    to: DatabaseInternal
end
