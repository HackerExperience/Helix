defmodule Helix.Network.Query.Tunnel do

  alias Helix.Network.Internal.Tunnel, as: TunnelInternal
  alias Helix.Network.Model.Connection
  alias Helix.Network.Model.Network
  alias Helix.Network.Model.Tunnel

  @type server :: HELL.PK.t

  @spec get_tunnel(Network.t, server, server, [server]) ::
    Tunnel.t
    | nil
  def get_tunnel(network, gateway, destination, bounces \\ []) do
    TunnelInternal.get_tunnel(network, gateway, destination, bounces)
  end

  @spec fetch(HELL.PK.t) :: Tunnel.t
  def fetch(id),
    do: TunnelInternal.fetch(id)

  @spec connected?(server, server, Network.t | nil) :: boolean
  def connected?(gateway, destination, network \\ nil) do
    TunnelInternal.connected?(gateway, destination, network)
  end

  @spec get_connections(Tunnel.t) :: [Connection.t]
  def get_connections(tunnel) do
    TunnelInternal.get_connections(tunnel)
  end

  @spec fetch_connection(HELL.PK.t) :: Connection.t | nil
  def fetch_connection(connection_id),
    do: TunnelInternal.fetch_connection(connection_id)

  @spec connections_through_node(server) :: [Connection.t]
  def connections_through_node(server) do
    TunnelInternal.connections_through_node(server)
  end

  @spec inbound_connections(server) :: [Connection.t]
  # REVIEW: Maybe return only connections whose tunnel's destination is `server`
  def inbound_connections(server) do
    TunnelInternal.inbound_connections(server)
  end

  @spec outbound_connections(server) :: [Connection.t]
  # REVIEW: Maybe return only connections whose tunnel's gateway is `server`
  def outbound_connections(server) do
    TunnelInternal.outbound_connections(server)
  end

  def connections_on_tunnels_between(gateway, endpoint) do
    TunnelInternal.connections_on_tunnels_between(gateway, endpoint)
  end
end
