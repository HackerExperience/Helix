defmodule Helix.Network.Henforcer.BounceTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Henforcer.Macros

  alias Helix.Network.Henforcer.Bounce, as: BounceHenforcer

  alias HELL.TestHelper.Random
  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Network.Setup, as: NetworkSetup

  defp create_link(network_id, ip, password),
    do: %{network_id: network_id, ip: ip, password: password}

  describe "bounce_exists?" do
    test "accepts when bounce exists" do
      {bounce, _} = NetworkSetup.Bounce.bounce()
      assert {true, relay} = BounceHenforcer.bounce_exists?(bounce.bounce_id)
      assert relay.bounce == bounce

      assert_relay relay, [:bounce]
    end

    test "rejects when bounce does not exist" do
      assert {false, reason, _} =
        BounceHenforcer.bounce_exists?(NetworkHelper.Bounce.id())
      assert reason == {:bounce, :not_found}
    end
  end

  describe "can_create_bounce?" do
    test "verifies everything" do
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

  describe "can_update_bounce?" do
    test "accepts when everything is ok" do
      {entity, _} = EntitySetup.entity()
      {bounce, _} = NetworkSetup.Bounce.bounce(entity_id: entity.entity_id)

      {server1, _} = ServerSetup.server()
      {server2, _} = ServerSetup.server()

      nip1 = ServerHelper.get_nip(server1)
      nip2 = ServerHelper.get_nip(server2)

      links =
        [
          create_link(nip1.network_id, nip1.ip, server1.password),
          create_link(nip2.network_id, nip2.ip, server2.password),
        ]

      assert {true, relay} =
        BounceHenforcer.can_update_bounce?(
          entity.entity_id, bounce.bounce_id, "newName", links
        )

      assert relay.bounce == bounce
      assert relay.entity == entity
      assert relay.servers == [server1, server2]

      assert_relay relay, [:bounce, :entity, :servers]
    end

    test "rejects when target bounce is being used by a tunnel" do
      {entity, _} = EntitySetup.entity()
      {bounce, _} = NetworkSetup.Bounce.bounce(entity_id: entity.entity_id)

      {_tunnel, _} = NetworkSetup.tunnel(bounce_id: bounce.bounce_id)

      {server1, _} = ServerSetup.server()
      {server2, _} = ServerSetup.server()

      nip1 = ServerHelper.get_nip(server1)
      nip2 = ServerHelper.get_nip(server2)

      links =
        [
          create_link(nip1.network_id, nip1.ip, server1.password),
          create_link(nip2.network_id, nip2.ip, server2.password),
        ]

      assert {false, reason, _} =
        BounceHenforcer.can_update_bounce?(
          entity.entity_id, bounce.bounce_id, "newNaeme", links
        )
      assert reason == {:bounce, :in_use}
    end

    test "rejects when player does not have access to one of the links" do
      {entity, _} = EntitySetup.entity()
      {bounce, _} = NetworkSetup.Bounce.bounce(entity_id: entity.entity_id)

      {server, _} = ServerSetup.server()

      nip = ServerHelper.get_nip(server)
      links = [create_link(nip.network_id, nip.ip, Random.password())]

      assert {false, reason, _} =
        BounceHenforcer.can_update_bounce?(
          entity.entity_id, bounce.bounce_id, "newNaeme", links
        )
      assert reason == {:bounce, :no_access}
    end

    test "rejects when entity does not own the bounce" do
      assert {false, reason, _} =
          BounceHenforcer.can_update_bounce?(
            EntitySetup.id(), NetworkHelper.Bounce.id(), "newname", []
          )
      assert reason == {:entity, :not_found}
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

  describe "bounce_in_use?" do
    test "accepts when bounce is in use" do
      {bounce, _} = NetworkSetup.Bounce.bounce()

      # Start using it
      NetworkSetup.tunnel(bounce_id: bounce.bounce_id)

      assert {true, relay} = BounceHenforcer.bounce_in_use?(bounce.bounce_id)
      assert relay.bounce == bounce

      assert_relay relay, [:bounce]
    end

    test "rejects when bounce is not in use" do
      {bounce, _} = NetworkSetup.Bounce.bounce()

      assert {false, reason, _} =
        BounceHenforcer.bounce_in_use?(bounce.bounce_id)
      assert reason == {:bounce, :not_in_use}
    end
  end

  describe "bounce_not_in_use?" do
    test "accepts when bounce is not in use" do
      {bounce, _} = NetworkSetup.Bounce.bounce()

      assert {true, relay} =
        BounceHenforcer.bounce_not_in_use?(bounce.bounce_id)
      assert relay.bounce == bounce

      assert_relay relay, [:bounce]
    end

    test "rejects when bounce is in use" do
      {bounce, _} = NetworkSetup.Bounce.bounce()

      # Start using it
      NetworkSetup.tunnel(bounce_id: bounce.bounce_id)

      assert {false, reason, _} =
        BounceHenforcer.bounce_not_in_use?(bounce.bounce_id)
      assert reason == {:bounce, :in_use}
    end
  end
end
