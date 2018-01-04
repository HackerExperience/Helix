defmodule Helix.Network.Henforcer.NetworkTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Henforcer.Macros

  alias Helix.Network.Henforcer.Network, as: NetworkHenforcer
  alias Helix.Network.Model.Network

  alias HELL.TestHelper.Random
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Network.Setup, as: NetworkSetup

  describe "nip_exists?/2" do
    test "accepts when nip exists" do
      {server, _} = ServerSetup.server()
      nip = ServerHelper.get_nip(server)

      assert {true, relay} =
        NetworkHenforcer.nip_exists?(nip.network_id, nip.ip)

      assert relay.server == server
      assert_relay relay, [:server]
    end

    test "rejects when nip is not found" do
      assert {false, reason, _} =
        NetworkHenforcer.nip_exists?(Network.ID.generate(), Random.ipv4())
      assert reason == {:nip, :not_found}
    end
  end

  describe "network_exists?/1" do
    test "accepts when network exists" do
      {network, _} = NetworkSetup.network()

      assert {true, relay} =
        NetworkHenforcer.network_exists?(network.network_id)

      assert relay.network == network
      assert_relay relay, [:network]
    end

    test "rejects when network is not found" do
      assert {false, reason, _} =
        NetworkHenforcer.network_exists?(Network.ID.generate())
      assert reason == {:network, :not_found}
    end
  end
end
