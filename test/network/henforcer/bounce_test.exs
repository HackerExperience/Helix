defmodule Helix.Network.Henforcer.BounceTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Henforcer.Macros

  alias Helix.Network.Henforcer.Bounce, as: BounceHenforcer

  alias HELL.TestHelper.Random
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Network.Helper, as: NetworkHelper

  describe "can_create_bounce?" do
    test "verifies everything" do
      # NOTE: Currently only verifies `links`
      {server1, %{entity: entity}} = ServerSetup.server()
      {server2, _} = ServerSetup.server()

      nip1 = ServerHelper.get_nip(server1)
      nip2 = ServerHelper.get_nip(server2)

      links =
        [
          create_link(nip1.network_id, nip1.ip, server1.password),
          create_link(nip2.network_id, nip2.ip, server2.password),
        ]

      assert {true, relay} =
        BounceHenforcer.can_create_bounce?(entity.entity_id, "noname", links)
      assert relay.servers == [server1, server2]
      assert_relay relay, [:servers]
    end
  end

  describe "has_access_links?" do
    test "verifies links access" do
      {server1, _} = ServerSetup.server()
      {server2, _} = ServerSetup.server()

      nip1 = ServerHelper.get_nip(server1)
      nip2 = ServerHelper.get_nip(server2)

      links =
        [
          create_link(nip1.network_id, nip1.ip, server1.password),
          create_link(nip2.network_id, nip2.ip, server2.password),
        ]

      assert {true, relay} = BounceHenforcer.has_access_links?(links)
      assert relay.servers == [server1, server2]
      assert_relay relay, [:servers]

      # Let's try again, now with bad password on one of the links
      links =
        [
          create_link(nip1.network_id, nip1.ip, server1.password),
          create_link(nip2.network_id, nip2.ip, Random.password()),
        ]

      assert {false, reason, _} = BounceHenforcer.has_access_links?(links)
      assert reason == {:bounce, :no_access}

      # Now with a bad nip
      links =
        [
          create_link(nip1.network_id, NetworkHelper.ip(), server1.password),
          create_link(nip2.network_id, nip2.ip, server2.password),
        ]

      assert {false, reason, _} = BounceHenforcer.has_access_links?(links)
      assert reason == {:nip, :not_found}
    end

    defp create_link(network_id, ip, password),
      do: %{network_id: network_id, ip: ip, password: password}
  end

  describe "has_access?" do
    test "accepts when NIP and password are valid" do
      {server, _} = ServerSetup.server()
      nip = ServerHelper.get_nip(server)

      assert {true, relay} =
        BounceHenforcer.has_access?(nip.network_id, nip.ip, server.password)
      assert relay.server == server

      assert_relay relay, [:server]
    end

    test "rejects when password is invalid" do
      {server, _} = ServerSetup.server()
      nip = ServerHelper.get_nip(server)

      assert {false, reason, _} =
        BounceHenforcer.has_access?(nip.network_id, nip.ip, Random.password())
      assert reason == {:bounce, :no_access}
    end

    test "rejects when server (nip) is not found" do
      assert {false, reason, _} =
        BounceHenforcer.has_access?(
          NetworkHelper.id(), NetworkHelper.ip(), Random.password()
        )

      assert reason == {:nip, :not_found}
    end
  end
end
