defmodule Helix.Network.Action.Flow.Tunnel do

  import HELF.Flow

  alias Helix.Event
  alias Helix.Server.Model.Server
  alias Helix.Network.Action.Tunnel, as: TunnelAction
  alias Helix.Network.Model.Bounce
  alias Helix.Network.Model.Connection
  alias Helix.Network.Model.Network
  alias Helix.Network.Model.Tunnel
  alias Helix.Network.Query.Bounce, as: BounceQuery
  alias Helix.Network.Query.Network, as: NetworkQuery
  alias Helix.Network.Query.Tunnel, as: TunnelQuery

  @type connect_errors :: term

  @spec connect(Tunnel.t, Connection.info, Event.relay) ::
    {:ok, Tunnel.t, Connection.t}
  @doc """
  Creates a connection of `type` with `meta` within the given `tunnel.`

  Emits: `ConnectionStartedEvent`
  """
  def connect(tunnel = %Tunnel{}, {type, meta}, relay) do
    flowing do
      with \
        {:ok, connection, events} <-
          TunnelAction.start_connection(tunnel, type, meta),

        on_success(fn -> Event.emit(events, from: relay) end),
        on_fail(fn -> TunnelAction.close_connection(connection) end)
      do
        {:ok, tunnel, connection}
      end
    end
  end

  @spec connect(
    Network.idt,
    Server.id,
    Server.id,
    Tunnel.bounce_idt,
    Connection.info,
    Event.relay)
  ::
    {:ok, Tunnel.t, Connection.t}
  @doc """
  Creates the connection of `type` on the tunnel between `gateway_id` and
  `target_id`, located at `network`, going through `bounce`. If this tunnel does
  not exist, a new one will be created.

  Emits: (`ConnectionStartedEvent`)
  """
  def connect(network, gateway_id, target_id, bounce, info, relay) do
    network = get_network(network)

    # Fetch tunnel (or create if it doesn't exist)
    tunnel = create_or_get_tunnel(network, gateway_id, target_id, bounce)

    # Delegate creation to `connect/3`
    connect(tunnel, info, relay)
  end

  @spec connect_once(
    Network.idt,
    Server.id,
    Server.id,
    Tunnel.bounce_idt,
    Connection.info,
    Event.relay)
  ::
    {:ok, Tunnel.t, Connection.t}
  @doc """
  Creates the connection - and the underlying tunnel if required - only if the
  requested connection of type `type` does not already exists.

  Emits: (`ConnectionStartedEvent`)
  """
  def connect_once(network, gateway_id, target_id, bounce, info, relay) do
    network = get_network(network)

    tunnel = create_or_get_tunnel(network, gateway_id, target_id, bounce)

    # Check if there already is a connection with the given information
    with connection = %{} <- find_connection(tunnel, info) do
      # Tunnel has connection with `{type, meta}`, so return it right away
      {:ok, tunnel, connection}
    else
      # Tunnel exists but there's no connection
      nil ->
        connect(tunnel, info, relay)
    end
  end

  @spec create_or_get_tunnel(
    Network.idt, Server.id, Server.id, Tunnel.bounce_idt)
  ::
    Tunnel.t
  defp create_or_get_tunnel(net, gateway, target, bounce_id = %Bounce.ID{}) do
    bounce = BounceQuery.fetch(bounce_id)

    create_or_get_tunnel(net, gateway, target, bounce)
  end
  defp create_or_get_tunnel(network, gateway_id, target_id, bounce) do
    with \
      nil <- TunnelQuery.get_tunnel(gateway_id, target_id, network, bounce)
    do
      {:ok, tunnel} =
        TunnelAction.create_tunnel(network, gateway_id, target_id, bounce)

      tunnel
    end
  end

  @spec find_connection(Tunnel.t | [Connection.t], Connection.info) ::
    Connection.t
    | nil
  defp find_connection(tunnel = %Tunnel{}, info) do
    tunnel
    |> TunnelQuery.get_connections()
    |> find_connection(info)
  end
  defp find_connection(connections, {type, meta}) do
    Enum.find(connections, fn connection ->
      connection.connection_type == type && connection.meta == meta
    end)
  end

  @spec get_network(Network.idt) ::
    Network.t
  defp get_network(network = %Network{}),
    do: network
  defp get_network(network_id = %Network.ID{}),
    do: NetworkQuery.fetch(network_id)
end
