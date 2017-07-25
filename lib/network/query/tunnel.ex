defmodule Helix.Network.Query.Tunnel do

  alias Helix.Server.Model.Server
  alias Helix.Network.Internal.Tunnel, as: TunnelInternal
  alias Helix.Network.Model.Connection
  alias Helix.Network.Model.Network
  alias Helix.Network.Model.Tunnel

  @spec get_tunnel(Network.t, Server.id, Server.id, [Server.id]) ::
    Tunnel.t
    | nil
  defdelegate get_tunnel(network, gateway_id, endpoint_id, bounces \\ []),
    to: TunnelInternal

  @spec fetch(Tunnel.id) ::
    Tunnel.t
    | nil
  defdelegate fetch(id),
    to: TunnelInternal

  @spec fetch_from_connection(Connection.t) ::
    Tunnel.t
  def fetch_from_connection(%Connection{tunnel_id: id}),
    do: fetch(id)

  @spec connected?(Server.id, Server.id, Network.t | nil) ::
    boolean
  defdelegate connected?(gateway_id, endpoint_id, network \\ nil),
    to: TunnelInternal

  @spec get_connections(Tunnel.t) ::
    [Connection.t]
  defdelegate get_connections(tunnel),
    to: TunnelInternal

  @spec fetch_connection(Connection.id) ::
    Connection.t
    | nil
  defdelegate fetch_connection(connection_id),
    to: TunnelInternal

  @spec connections_through_node(Server.id) ::
    [Connection.t]
  defdelegate connections_through_node(server_id),
    to: TunnelInternal

  @spec inbound_connections(Server.id) ::
    [Connection.t]
  # REVIEW: Maybe return only connections whose tunnel's destination is `server`
  defdelegate inbound_connections(endpoint_id),
    to: TunnelInternal

  @spec outbound_connections(Server.id) ::
    [Connection.t]
  # REVIEW: Maybe return only connections whose tunnel's gateway is `server`
  defdelegate outbound_connections(gateway_id),
    to: TunnelInternal

  @spec connections_on_tunnels_between(Server.id, Server.id) ::
    [Connection.t]
  defdelegate connections_on_tunnels_between(gateway_id, endpoint_id),
    to: TunnelInternal
end
