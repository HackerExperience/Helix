defmodule Helix.Network.Event.Tunnel do

  alias Helix.Network.Model.Connection.ConnectionClosedEvent
  alias Helix.Network.Action.Tunnel, as: TunnelAction
  alias Helix.Network.Query.Tunnel, as: TunnelQuery

  def connection_closed(e = %ConnectionClosedEvent{}) do
    tunnel = TunnelQuery.fetch(e.tunnel_id)

    if Enum.empty?(TunnelQuery.get_connections(tunnel)) do
      TunnelAction.delete(tunnel)
    end
  end
end
