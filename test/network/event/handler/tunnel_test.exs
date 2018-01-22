defmodule Helix.Network.Event.Handler.TunnelTest do

  use Helix.Test.Case.Integration

  alias Helix.Network.Action.Tunnel, as: TunnelAction
  alias Helix.Network.Query.Tunnel, as: TunnelQuery

  alias Helix.Test.Event.Helper, as: EventHelper
  alias Helix.Test.Network.Setup, as: NetworkSetup

  describe "when connection is closed" do
    test "deletes tunnel if it is empty" do
      {tunnel, _} = NetworkSetup.tunnel()

      {:ok, connection, _} = TunnelAction.start_connection(tunnel, :ssh)
      events = TunnelAction.close_connection(connection)

      EventHelper.emit(events)

      refute TunnelQuery.fetch(tunnel.tunnel_id)
    end

    test "does nothing if tunnel still has connections" do
      {tunnel, _} = NetworkSetup.tunnel()

      TunnelAction.start_connection(tunnel, :ssh)
      {:ok, connection, _} = TunnelAction.start_connection(tunnel, :ssh)

      events = TunnelAction.close_connection(connection)
      EventHelper.emit(events)

      assert TunnelQuery.fetch(tunnel.tunnel_id)
    end
  end
end
