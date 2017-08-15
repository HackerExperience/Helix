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

  @spec connected?(Server.idt, Server.idt, Network.t | nil) ::
    boolean
  defdelegate connected?(gateway_id, endpoint_id, network \\ nil),
    to: TunnelInternal

  @spec get_connections(Tunnel.t) ::
    [Connection.t]
  defdelegate get_connections(tunnel),
    to: TunnelInternal

  @spec fetch_connection(Connection.idt) ::
    Connection.t
    | nil
  defdelegate fetch_connection(connection),
    to: TunnelInternal

  @spec connections_through_node(Server.idt) ::
    [Connection.t]
  defdelegate connections_through_node(server),
    to: TunnelInternal

  @spec inbound_connections(Server.idt) ::
    [Connection.t]
  # REVIEW: Maybe return only connections whose tunnel's destination is `server`
  defdelegate inbound_connections(endpoint),
    to: TunnelInternal

  @spec outbound_connections(Server.idt) ::
    [Connection.t]
  # REVIEW: Maybe return only connections whose tunnel's gateway is `server`
  defdelegate outbound_connections(gateway),
    to: TunnelInternal

  @spec connections_on_tunnels_between(Server.idt, Server.idt) ::
    [Connection.t]
  defdelegate connections_on_tunnels_between(gateway, endpoint),
    to: TunnelInternal

  defdelegate get_links(tunnel),
    to: TunnelInternal

  @spec get_hops(Tunnel.t) ::
    [Server.id]
  def get_hops(tunnel) do
    tunnel
    |> TunnelInternal.get_links()
    |> Enum.reduce([], fn(link, acc) ->
      acc ++ [link.source_id] ++ [link.destination_id]
    end)
    |> Enum.uniq()
  end
end
