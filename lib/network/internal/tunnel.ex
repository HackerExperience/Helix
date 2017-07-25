defmodule Helix.Network.Internal.Tunnel do

  alias Helix.Event
  alias Helix.Server.Model.Server
  alias Helix.Network.Model.Connection
  alias Helix.Network.Model.Network
  alias Helix.Network.Model.Tunnel
  alias Helix.Network.Repo

  import Ecto.Query, only: [select: 3]

  @spec create(Network.t, Server.id, Server.id, [Server.id]) ::
    {:ok, Tunnel.t}
    | {:error, Ecto.Changeset.t}
  @doc """
  Creates a new tunnel
  """
  def create(network, gateway_id, endpoint_id, bounces \\ []) do
    cs = Tunnel.create(network, gateway_id, endpoint_id, bounces)
    Repo.insert(cs)
  end

  @spec get_tunnel(Network.t, Server.id, Server.id, [Server.id]) ::
    Tunnel.t
    | nil
  @doc """
  Returns the tunnel with the input configuration shall it exist
  """
  def get_tunnel(network, gateway_id, endpoint_id, bounces \\ []) do
    tunnel_hash = Tunnel.hash_bounces(bounces)

    fetch_clauses = [
      network_id: network.network_id,
      gateway_id: gateway_id,
      destination_id: endpoint_id,
      hash: tunnel_hash
    ]

    Repo.get_by(Tunnel, fetch_clauses)
  end

  @spec fetch(Tunnel.id) ::
    Tunnel.t
    | nil
  def fetch(id),
    do: Repo.get(Tunnel, id)

  @spec delete(Tunnel.t | Tunnel.id) ::
    :ok
  def delete(%Tunnel{tunnel_id: id}),
    do: delete(id)
  def delete(id) do
    id
    |> Tunnel.Query.by_id()
    |> Repo.delete_all()

    :ok
  end

  @spec connected?(Server.id, Server.id, Network.t | nil) ::
    boolean
  def connected?(gateway_id, endpoint_id, network \\ nil) do
    query =
      Tunnel
      |> select([t], count(t.tunnel_id))
      |> Tunnel.Query.by_gateway_id(gateway_id)
      |> Tunnel.Query.by_destination_id(endpoint_id)

    query =
      network
      && Tunnel.Query.from_network(query, network)
      || query

    count = Repo.one(query)

    is_integer(count) and count > 0
  end

  @spec get_connections(Tunnel.t) ::
    [Connection.t]
  def get_connections(tunnel) do
    Repo.preload(tunnel, :connections).connections
  end

  @spec fetch_connection(Connection.id) ::
    Connection.t
    | nil
  def fetch_connection(connection_id),
    do: Repo.get(Connection, connection_id)

  @spec connections_through_node(Server.id) ::
    [Connection.t]
  def connections_through_node(server_id) do
    server_id
    |> Connection.Query.through_node()
    |> Repo.all()
  end

  @spec inbound_connections(Server.id) ::
    [Connection.t]
  # REVIEW: Maybe return only connections whose tunnel's destination is `server`
  def inbound_connections(endpoint_id) do
    endpoint_id
    |> Connection.Query.inbound_to()
    |> Repo.all()
  end

  @spec outbound_connections(Server.id) ::
    [Connection.t]
  # REVIEW: Maybe return only connections whose tunnel's gateway is `server`
  def outbound_connections(gateway_id) do
    gateway_id
    |> Connection.Query.outbound_from()
    |> Repo.all()
  end

  @spec start_connection(Tunnel.t, Connection.type) ::
    {:ok, Connection.t, [Event.t]}
    | {:error, Ecto.Changeset.t}
  def start_connection(tunnel, connection_type) do
    cs = Connection.create(tunnel, connection_type)

    with {:ok, connection} <- Repo.insert(cs) do
      event = %Connection.ConnectionStartedEvent{
        connection_id: connection.connection_id,
        tunnel_id: connection.tunnel_id,
        network_id: tunnel.network_id,
        connection_type: connection_type
      }

      {:ok, connection, [event]}
    end
  end

  @spec close_connection(Connection.t, Connection.close_reasons) ::
    [Event.t]
    | no_return
  @doc """
  Closes `connection`

  This can simply mean deleting the connection and, as an event reaction,
  cancelling any action that depends on this process.

  `reason` is an atom to "justify" the reason the connection is being closed.
  This is used by the event handlers to provide meaningful side-effects based on
  what happened.

  The current reasons are valid: #{inspect Connection.close_reasons()}
  """
  def close_connection(connection = %Connection{}, reason \\ :normal) do
    connection = Repo.preload(connection, :tunnel)

    Repo.delete!(connection)

    event = %Connection.ConnectionClosedEvent{
      connection_id: connection.connection_id,
      tunnel_id: connection.tunnel_id,
      network_id: connection.tunnel.network_id,
      reason: reason
    }

    [event]
  end

  @spec connections_on_tunnels_between(Server.id, Server.id) ::
    [Connection.t]
  def connections_on_tunnels_between(gateway_id, endpoint_id) do
    gateway_id
    |> Connection.Query.from_gateway_to_endpoint(endpoint_id)
    |> Repo.all()
  end
end
