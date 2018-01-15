defmodule Helix.Network.Internal.Tunnel do

  alias Helix.Server.Model.Server
  alias Helix.Network.Model.Connection
  alias Helix.Network.Model.Link
  alias Helix.Network.Model.Network
  alias Helix.Network.Model.Tunnel
  alias Helix.Network.Repo

  # TODO: Refactor TunnelInternal
  alias Helix.Network.Event.Connection.Closed, as: ConnectionClosedEvent
  alias Helix.Network.Event.Connection.Started, as: ConnectionStartedEvent

  @spec fetch(Tunnel.id) ::
    Tunnel.t
    | nil
  def fetch(id),
    do: Repo.get(Tunnel, id)

  @spec fetch_connection(Connection.id) ::
    Connection.t
    | nil
  def fetch_connection(id),
    do: Repo.get(Connection, id)

  @spec create(Network.t, Server.id, Server.id, [Server.id]) ::
    {:ok, Tunnel.t}
    | {:error, Ecto.Changeset.t}
  @doc """
  Creates a new tunnel
  """
  def create(network, gateway_id, endpoint_id, bounces \\ []) do
    network
    |> Tunnel.create(gateway_id, endpoint_id, bounces)
    |> Repo.insert()
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

  @spec delete(Tunnel.t) ::
    :ok
  def delete(tunnel) do
    Repo.delete(tunnel)

    :ok
  end

  @spec connected?(Server.idt, Server.idt, Network.idt | nil) ::
    boolean
  def connected?(gateway_id, endpoint_id, network \\ nil) do
    query =
      Tunnel
      |> Tunnel.Query.select_total_tunnels()
      |> Tunnel.Query.by_gateway(gateway_id)
      |> Tunnel.Query.by_destination(endpoint_id)

    query =
      network
      && Tunnel.Query.by_network(query, network)
      || query

    count = Repo.one(query)

    is_integer(count) and count > 0
  end

  @spec get_connections(Tunnel.t) ::
    [Connection.t]
  def get_connections(tunnel) do
    Repo.preload(tunnel, :connections).connections
  end

  @spec connections_through_node(Server.idt) ::
    [Connection.t]
  def connections_through_node(server_id) do
    server_id
    |> Connection.Query.through_node()
    |> Repo.all()
  end

  @spec inbound_connections(Server.idt) ::
    [Connection.t]
  def inbound_connections(endpoint_id) do
    endpoint_id
    |> Connection.Query.inbound_to()
    |> Repo.all()
  end

  @spec outbound_connections(Server.idt) ::
    [Connection.t]
  def outbound_connections(gateway_id) do
    gateway_id
    |> Connection.Query.outbound_from()
    |> Repo.all()
  end

  @spec connections_originating_from(Server.idt) ::
    [Connection.t]
  def connections_originating_from(gateway_id) do
    gateway_id
    |> Tunnel.Query.by_gateway()
    |> Repo.all()
    |> Enum.flat_map(&(get_connections(&1)))
  end

  @spec connections_destined_to(Server.idt) ::
    [Connection.t]
  def connections_destined_to(endpoint_id) do
    endpoint_id
    |> Tunnel.Query.by_destination()
    |> Repo.all()
    |> Enum.flat_map(&(get_connections(&1)))
  end

  @spec start_connection(Tunnel.t, Connection.type, Connection.meta) ::
    {:ok, Connection.t}
    | {:error, Ecto.Changeset.t}
  def start_connection(tunnel, connection_type, meta \\ nil) do
    result =
      tunnel
      |> Connection.create(connection_type, meta)
      |> Repo.insert()

    with {:ok, connection} <- result do
      {:ok, Repo.preload(connection, :tunnel)}
    end
  end

  @spec close_connection(Connection.t, Connection.close_reasons) ::
    [ConnectionClosedEvent.t]
    | no_return
  @doc """
  Closes `connection`

  This can simply mean deleting the connection and, as an event reaction,
  canceling any action that depends on this process.

  `reason` is an atom to "justify" the reason the connection is being closed.
  This is used by the event handlers to provide meaningful side-effects based on
  what happened.

  The current reasons are valid: #{inspect Connection.close_reasons()}
  """
  def close_connection(connection = %Connection{}, reason \\ :normal) do
    event =
      connection
      |> Repo.preload(:tunnel)
      |> ConnectionClosedEvent.new(reason)

    Repo.delete!(connection)

    [event]
  end

  @spec connections_on_tunnels_between(Server.id, Server.id) ::
    [Connection.t]
  def connections_on_tunnels_between(gateway_id, endpoint_id) do
    gateway_id
    |> Connection.Query.from_gateway_to_endpoint(endpoint_id)
    |> Repo.all()
    end

  @spec get_links(Tunnel.idt) ::
    [Link.t]
  def get_links(tunnel) do
    tunnel
    |> Link.Query.by_tunnel()
    |> Link.Query.order_by_sequence()
    |> Repo.all()
  end

  @spec get_remote_endpoints([Server.idt]) ::
    Tunnel.gateway_endpoints
  def get_remote_endpoints(servers) do
    query =
      servers
      |> Tunnel.Query.get_remote_endpoints()

    {:ok, result} = Ecto.Adapters.SQL.query(Repo, query, [])

    Enum.reduce(result.rows, %{}, fn row, acc ->
      [gateway_id, destination_id, network_id, bounces] = row

      gateway_id = Server.ID.cast!(gateway_id)

      data = %{
        destination_id: Server.ID.cast!(destination_id),
        bounces: Enum.map(bounces, &(Server.ID.cast!(&1))),
        network_id: Network.ID.cast!(network_id)
      }

      acc
      |> Map.put(gateway_id, [data] ++ Map.get(acc, gateway_id, []))
    end)
  end
end
