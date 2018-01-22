defmodule Helix.Network.Query.TunnelTest do

  use Helix.Test.Case.Integration

  alias Helix.Network.Query.Tunnel, as: TunnelQuery

  alias Helix.Test.Network.Setup, as: NetworkSetup

  describe "get_hops/1" do
    test "without bounce" do
      {tunnel, _} = NetworkSetup.tunnel(fake_servers: true)

      assert [tunnel.gateway_id, tunnel.destination_id] ==
        TunnelQuery.get_hops(tunnel)
    end

    test "with bounce" do
      {bounce, _} = NetworkSetup.Bounce.bounce(total: 2)
      [{hop1_id, _, _}, {hop2_id, _, _}] = bounce.links

      {tunnel, _} =
        NetworkSetup.tunnel(bounce_id: bounce.bounce_id, fake_servers: true)

      assert [tunnel.gateway_id, hop1_id, hop2_id, tunnel.destination_id] ==
        TunnelQuery.get_hops(tunnel)
    end
  end
end
