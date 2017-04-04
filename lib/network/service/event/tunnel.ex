defmodule Helix.Network.Service.Event.Tunnel do

  alias Helix.Network.Model.ConnectionClosedEvent
  alias Helix.Network.Controller.Tunnel

  def connection_closed(e = %ConnectionClosedEvent{}) do
    tunnel = Tunnel.fetch(e.tunnel_id)

    if Enum.empty?(Tunnel.get_connections(tunnel)) do
      Tunnel.delete(tunnel)
    end
  end
end
