defmodule Helix.Network.Event.Handler.Tunnel do

  alias Helix.Network.Action.Tunnel, as: TunnelAction
  alias Helix.Network.Query.Tunnel, as: TunnelQuery

  alias Helix.Network.Event.Connection.Closed, as: ConnectionClosedEvent

  def connection_closed(event = %ConnectionClosedEvent{}) do
    if Enum.empty?(TunnelQuery.get_connections(event.tunnel)) do
      TunnelAction.delete(event.tunnel)
    end
  end
end
