defmodule Helix.Network.Controller.Tunnel do

  alias Helix.Network.Model.Connection
  alias Helix.Network.Model.Network
  alias Helix.Network.Model.Tunnel
  alias Helix.Network.Repo

  import Ecto.Query, only: [select: 3]

  @type server :: HELL.PK.t

  @spec prepare(Network.t, server, server, [server]) ::
    {:ok, Tunnel.t}
    | {:error, Ecto.Changeset.t}
  @doc """
  Provides a tunnel

  Will fetch a tunnel with the exact input configuration or create one if none
  exists
  """
  def prepare(network, gateway, destination, bounces \\ []) do
    tunnel_hash = Tunnel.hash_bounces(bounces)

    fetch_clauses = [
      network_id: network.network_id,
      gateway_id: gateway,
      destination_id: destination,
      hash: tunnel_hash
    ]

    tunnel = Repo.get_by(Tunnel, fetch_clauses)

    if tunnel do
      {:ok, tunnel}
    else
      cs = Tunnel.create(network, gateway, destination, bounces)
      Repo.insert(cs)
    end
  end

  @spec prepare!(Network.t, server, server, [server]) :: Tunnel.t | no_return
  def prepare!(network, gateway, destination, bounces \\ []) do
    case prepare(network, gateway, destination, bounces) do
      {:ok, tunnel} ->
        tunnel
      _ ->
        raise "failed to prepare network tunnel"
    end
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

  # REVIEW: Where do this belongs?
  @spec connections_through_node(server) :: [Connection.t]
  def connections_through_node(server) do
    server
    |> Connection.Query.through_node()
    |> Repo.all()
  end

  @spec fetch(HELL.PK.t) :: Tunnel.t
  def fetch(id),
    do: Repo.get(Tunnel, id)

  @spec get_connections(Tunnel.t) :: [Connection.t]
  def get_connections(tunnel) do
    Repo.preload(tunnel, :connections).connections
  end

  @spec start_connection(Tunnel.t, term) ::
    {:ok, Connection.t}
    | {:error, Ecto.Changeset.t}
  def start_connection(tunnel, connection_type) do
    tunnel
    |> Connection.create(connection_type)
    |> Repo.insert()
  end

  @spec close_connection(Connection.t, Connection.close_reasons) :: :ok
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
    connection
    |> Connection.close(reason)
    |> Repo.delete!()

    # TODO: return event
    :ok
  end
end
