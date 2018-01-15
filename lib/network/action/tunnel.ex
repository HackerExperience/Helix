defmodule Helix.Network.Action.Tunnel do

  alias Helix.Server.Model.Server
  alias Helix.Network.Internal.Tunnel, as: TunnelInternal
  alias Helix.Network.Model.Connection
  alias Helix.Network.Model.Network
  alias Helix.Network.Model.Tunnel
  alias Helix.Network.Query.Tunnel, as: TunnelQuery

  alias Helix.Network.Event.Connection.Closed, as: ConnectionClosedEvent
  alias Helix.Network.Event.Connection.Started, as: ConnectionStartedEvent

  @type create_tunnel_errors ::
    {:error, {:gateway_id, :notfound}}
    | {:error, {:destination_id, :notfound}}
    | {:error, {:links, :notfound}}
    | {:error, {:gateway_id, :disconnected}}
    | {:error, {:destination_id, :disconnected}}
    | {:error, {:links_id, :disconnected}}

  @spec connect(
    Network.t,
    Server.id,
    Server.id,
    [Server.id],
    Connection.type,
    Connection.meta)
  ::
    {:ok, Tunnel.t, Connection.t, [ConnectionStartedEvent.t]}
    | create_tunnel_errors
  @doc """
  Starts a connection between `gateway` and `destination` through `network`.

  The connection type is `connection_type`, and it shall pass by `bounces`.

  If there is already a tunnel with this configuration, it'll be reused,
  otherwise a new Tunnel will be created
  """
  def connect(network, gateway, destination, bounces, type, meta \\ nil) do
    tunnel = TunnelInternal.get_tunnel(network, gateway, destination, bounces)
    context =
      if tunnel do
        {:ok, tunnel}
      else
        create_tunnel(network, gateway, destination, bounces)
      end

    with \
      {:ok, tunnel} <- context,
      {:ok, connection} <- TunnelInternal.start_connection(tunnel, type, meta)
    do
      event = ConnectionStartedEvent.new(connection)

      {:ok, tunnel, connection, [event]}
    end
  end

  @spec create_tunnel(Network.t, Server.id, Server.id, [Server.id]) ::
    {:ok, Tunnel.t}
  defp create_tunnel(network, gateway, destination, bounces) do
    TunnelInternal.create(network, gateway, destination, bounces)
  end

  @spec delete(Tunnel.idt) ::
    :ok
  defdelegate delete(tunnel),
    to: TunnelInternal

  @spec start_connection(Tunnel.t, Connection.type, Connection.meta) ::
    {:ok, Connection.t, [ConnectionStartedEvent.t]}
    | {:error, Ecto.Changeset.t}
  defdelegate start_connection(tunnel, connection_type, meta \\ nil),
    to: TunnelInternal

  @spec close_connection(Connection.t, Connection.close_reasons) ::
    [ConnectionClosedEvent.t]
  defdelegate close_connection(connection, reason \\ :normal),
    to: TunnelInternal

  @spec close_connections_where(Server.idt, Server.idt, Connection.type, term) ::
    [ConnectionClosedEvent.t]
  @doc """
  Closes all connections where:
  - gateway is `from`
  - destination is `to`
  - type is `type`
  - Optional: filter meta values according to `meta_filter`

  The `meta_filter` param must be a function that receives the connection's meta
  field and returns true if that connection should be closed, false otherwise.
  Note that the connection's meta may be empty (nil). Also note that IDs stored
  on the meta will return as string, so use `to_string/1`.
  """
  def close_connections_where(from, to, type, meta_filter \\ false) do
    # Applies the meta_filter to the resulting set of connections. If no filter
    # is given, then the user wants to delete all returned connections.
    apply_filter = fn connections ->
      if meta_filter do
        connections
        |> Enum.filter(fn(entry) -> meta_filter.(entry.meta) end)
      else
        connections
      end
    end

    events =
      from
      |> TunnelQuery.connections_on_tunnels_between(to)
      |> Enum.filter(&(&1.connection_type == type))
      |> apply_filter.()
      |> Enum.map(&close_connection/1)
      |> Enum.concat()

    events
  end
end
