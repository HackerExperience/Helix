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
  @doc """
  Lists all inbound connections on the given server. It may include connections
  that have that server as final destination, as well as connections which are
  bouncing through (using that server as bounce).
  """
  defdelegate inbound_connections(endpoint),
    to: TunnelInternal

  @spec outbound_connections(Server.idt) ::
    [Connection.t]
  @doc """
  Lists all outbound connections on the given server. It may include connections
  that originated on that server, as well as connections which are bouncing
  through (using that server as bounce).
  """
  defdelegate outbound_connections(gateway),
    to: TunnelInternal

  @spec connections_originating_from(Server.idt) ::
    [Connection.t]
  @doc """
  Lists all connections that *originated* on the given server, i.e. the server
  is the gateway/starting point of the connection.
  """
  defdelegate connections_originating_from(gateway),
    to: TunnelInternal

  @spec connections_destined_to(Server.idt) ::
    [Connection.t]
  @doc """
  Lists all connections that have the given server as the final destination.
  """
  defdelegate connections_destined_to(endpoint),
    to: TunnelInternal

  @spec connections_on_tunnels_between(Server.idt, Server.idt) ::
    [Connection.t]
  defdelegate connections_on_tunnels_between(gateway, endpoint),
    to: TunnelInternal

  defdelegate get_links(tunnel),
    to: TunnelInternal

  @spec get_hops(Tunnel.t) ::
    [Server.id]
  @doc """
  Returns all hops in a tunnel, including source (gateway) and endpoint
  (destination).
  """
  def get_hops(tunnel) do
    tunnel
    |> TunnelInternal.get_links()
    |> Enum.reduce([], fn(link, acc) ->
      acc ++ [link.source_id] ++ [link.destination_id]
    end)
    |> Enum.uniq()
  end

  @spec get_remote_endpoints([Server.id]) ::
    Tunnel.remote_endpoints
  @doc """
  Returns information about remote connections (endpoints). For each given
  server, returns remote connections (if any) including destination_id and
  bounces/hops between the gateway and the endpoint.

  A server `B` is considered a `remote endpoint` of `S` if there's an SSH
  connection between `S` and `B`.
  """
  defdelegate get_remote_endpoints(servers),
    to: TunnelInternal
end
