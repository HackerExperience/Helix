defmodule Helix.Network.Controller.Tunnel do

  alias Helix.Network.Model.Connection
  alias Helix.Network.Model.Network
  alias Helix.Network.Model.Tunnel
  alias Helix.Network.Repo

  import Ecto.Query, only: [select: 3]

  @type server :: HELL.PK.t

  @spec create(Network.t, server, server, [server]) ::
    {:ok, Tunnel.t}
    | {:error, Ecto.Changeset.t}
  @doc """
  Creates a new tunnel
  """
  def create(network, gateway, destination, bounces \\ []) do
    cs = Tunnel.create(network, gateway, destination, bounces)
    Repo.insert(cs)
  end

  @spec get_tunnel(Network.t, server, server, [server]) ::
    Tunnel.t
    | nil
  @doc """
  Returns the tunnel with the input configuration shall it exist
  """
  def get_tunnel(network, gateway, destination, bounces \\ []) do
    tunnel_hash = Tunnel.hash_bounces(bounces)

    fetch_clauses = [
      network_id: network.network_id,
      gateway_id: gateway,
      destination_id: destination,
      hash: tunnel_hash
    ]

    Repo.get_by(Tunnel, fetch_clauses)
  end

  @spec fetch(HELL.PK.t) :: Tunnel.t
  def fetch(id),
    do: Repo.get(Tunnel, id)

  @spec delete(Tunnel.t) :: :ok
  def delete(%Tunnel{tunnel_id: id}),
    do: delete(id)
  def delete(id) do
    id
    |> Tunnel.Query.by_id()
    |> Repo.delete_all()

    :ok
  end

  @spec connected?(server, server, Network.t | nil) :: boolean
  def connected?(gateway, destination, network \\ nil) do
    query =
      Tunnel
      |> select([t], count(t.tunnel_id))
      |> Tunnel.Query.by_gateway_id(gateway)
      |> Tunnel.Query.by_destination_id(destination)

    query =
      network
      && Tunnel.Query.from_network(query, network)
      || query

    count = Repo.one(query)

    is_integer(count) and count > 0
  end

  @spec get_connections(Tunnel.t) :: [Connection.t]
  def get_connections(tunnel) do
    Repo.preload(tunnel, :connections).connections
  end

  @spec fetch_connection(HELL.PK.t) :: Connection.t | nil
  def fetch_connection(connection_id),
    do: Repo.get(Connection, connection_id)

  @spec connections_through_node(server) :: [Connection.t]
  def connections_through_node(server) do
    server
    |> Connection.Query.through_node()
    |> Repo.all()
  end

  @spec inbound_connections(server) :: [Connection.t]
  # REVIEW: Maybe return only connections whose tunnel's destination is `server`
  def inbound_connections(server) do
    server
    |> Connection.Query.inbound_to()
    |> Repo.all()
  end

  @spec outbound_connections(server) :: [Connection.t]
  # REVIEW: Maybe return only connections whose tunnel's gateway is `server`
  def outbound_connections(server) do
    server
    |> Connection.Query.outbound_from()
    |> Repo.all()
  end

  @spec start_connection(Tunnel.t, term) ::
    {:ok, Connection.t, [event :: struct]}
    | {:error, Ecto.Changeset.t}
  def start_connection(tunnel, connection_type) do
    cs = Connection.create(tunnel, connection_type)

    with {:ok, connection} <- Repo.insert(cs) do
      event = %Connection.ConnectionStartedEvent{
        connection_id: connection.connection_id,
        tunnel_id: connection.tunnel_id,
        network_id: tunnel.network_id
      }

      {:ok, connection, [event]}
    end
  end

  @spec close_connection(Connection.t, Connection.close_reasons) ::
    [event :: struct]
  @doc """
  Closes `connection`

  This can simply mean deleting the connection and, as an event reaction,
  cancelling any action that depends on this process.

  `reason` is an atom to "justify" the reason the connection is being closed.
  This is used by the event handlers to provide meaningful side-effects based on
  what happened.

  The current reasons are valid: #{inspect Connection.close_reasons()}
  """
  def close_connection(connection, reason \\ :normal) do
    connection = Repo.preload(connection, :tunnel)

    Repo.delete!(connection)

    event = %Helix.Network.Model.ConnectionClosedEvent{
      connection_id: connection.connection_id,
      tunnel_id: connection.tunnel_id,
      network_id: connection.tunnel.network_id,
      reason: reason
    }

    [event]
  end
end
