defmodule Helix.Network.Event.Tunnel do

  alias Helix.Network.Model.Connection.ConnectionClosedEvent
  alias Helix.Network.Action.Tunnel, as: TunnelAction
  alias Helix.Network.Query.Tunnel, as: TunnelQuery

  def connection_closed(event = %ConnectionClosedEvent{}) do
    if Enum.empty?(TunnelQuery.get_connections(event.tunnel)) do
      TunnelAction.delete(event.tunnel)
    end
  end
end
