defmodule Helix.Server.Action.ServerTest do

  use Helix.Test.Case.Integration

  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Server.Action.Server, as: ServerAction
  alias Helix.Server.Query.Server, as: ServerQuery

  alias HELL.TestHelper.Random
  alias Helix.Test.Cache.Helper, as: CacheHelper
  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Server.Component.Setup, as: ComponentSetup

  describe "create/2" do
    test "succeeds with valid input" do
      assert {:ok, server} = ServerAction.create(:desktop)
      assert server.type == :desktop
      refute server.motherboard_id
      assert server.password
    end

    test "fails when input is invalid" do
      assert {:error, cs} = ServerAction.create(:invalid)
      refute cs.valid?
    end
  end

  describe "attach/2" do
    test "succeeds with valid input" do
      {server, _} = ServerSetup.server(motherboard_id: nil)
      {mobo, _} = ComponentSetup.component(type: :mobo)

      assert {:ok, server} = ServerAction.attach(server, mobo.component_id)
      assert server.motherboard_id == mobo.component_id

      CacheHelper.sync_test()
    end

    test "succeeds when server already has a motherboard" do
      {server, _} = ServerSetup.server()

      {mobo, _} = ComponentSetup.component(type: :mobo)

      assert {:ok, new_server} = ServerAction.attach(server, mobo.component_id)
      assert new_server.motherboard_id == mobo.component_id

      CacheHelper.sync_test()
    end

    test "fails when given motherboard is already attached" do
      {server1, _} = ServerSetup.server()
      {server2, _} = ServerSetup.server()

      assert {:error, reason} =
        ServerAction.attach(server1, server2.motherboard_id)
      assert reason == :internal

      CacheHelper.sync_test()
    end
  end

  describe "detach/1" do
    test "is idempotent" do
      {server, _} = ServerSetup.server()

      ServerAction.detach(server)
      ServerAction.detach(server)

      server = ServerQuery.fetch(server.server_id)
      refute server.motherboard_id

      CacheHelper.sync_test()
    end
  end

  describe "delete/1" do
    test "removes the record from database" do
      {server, _} = ServerSetup.server()

      assert ServerQuery.fetch(server.server_id)

      ServerAction.delete(server)

      refute ServerQuery.fetch(server.server_id)

      CacheHelper.sync_test()
    end
  end

  describe "crack/4" do
    test "retrieves the password of the target server" do
      attacker = EntitySetup.id()
      {target, _} = ServerSetup.server()

      {:ok, [nip]} = CacheQuery.from_server_get_nips(target.server_id)

      # Password was retrieved!
      assert {:ok, password, [event]} =
        ServerAction.crack(attacker, target.server_id, nip.network_id, nip.ip)

      # Password is correct
      assert password == target.password

      # Event data is correct
      assert event.password == target.password
      assert event.entity_id == attacker
      assert event.server_id == target.server_id
      assert event.network_id == nip.network_id
      assert event.server_ip == nip.ip
    end

    test "fails in case target nip is not found" do
      attacker = EntitySetup.id()

      target_id = ServerSetup.id()
      network_id = NetworkHelper.internet_id()
      ip = Random.ipv4()

      # It failed to crack
      assert {:error, reason, [event]} =
        ServerAction.crack(attacker, target_id, network_id, ip)

      # Because NIP was not found (may have changed, etc)
      assert reason == {:nip, :notfound}

      # And the event data is correct
      assert event.entity_id == attacker
      assert event.network_id == network_id
      assert event.server_id == target_id
      assert event.server_ip == ip
      assert event.reason == :nip_notfound
    end
  end
end
