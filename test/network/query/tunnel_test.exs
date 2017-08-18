defmodule Helix.Network.Query.TunnelTest do

  use Helix.Test.Case.Integration

  alias Helix.Server.Model.Server
  alias Helix.Network.Query.Network, as: NetworkQuery
  alias Helix.Network.Query.Tunnel, as: TunnelQuery

  alias Helix.Test.Network.Factory

  @internet NetworkQuery.internet()

  describe "get_hops/1" do
    test "with a direct connection" do
      gateway_id = Server.ID.generate()
      destination_id = Server.ID.generate()

      tunnel = Factory.insert(:tunnel,
        network: @internet,
        gateway_id: gateway_id,
        destination_id: destination_id,
        bounces: [])

      assert [gateway_id, destination_id] == TunnelQuery.get_hops(tunnel)
    end

    test "with n=1 bounce" do
      gateway_id = Server.ID.generate()
      destination_id = Server.ID.generate()
      bounce1 = Server.ID.generate()

      tunnel = Factory.insert(:tunnel,
        network: @internet,
        gateway_id: gateway_id,
        destination_id: destination_id,
        bounces: [bounce1])

      assert [gateway_id, bounce1, destination_id] ==
        TunnelQuery.get_hops(tunnel)
    end

    test "with n>1 bounce" do
      gateway_id = Server.ID.generate()
      destination_id = Server.ID.generate()
      bounce1 = Server.ID.generate()
      bounce2 = Server.ID.generate()

      tunnel = Factory.insert(:tunnel,
        network: @internet,
        gateway_id: gateway_id,
        destination_id: destination_id,
        bounces: [bounce1, bounce2])

      assert [gateway_id, bounce1, bounce2, destination_id] ==
        TunnelQuery.get_hops(tunnel)
    end
  end

end
