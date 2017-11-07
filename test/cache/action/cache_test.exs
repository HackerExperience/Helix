defmodule Helix.Cache.Action.CacheTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Case.Cache
  import Helix.Test.Case.ID

  alias Helix.Server.Internal.Server, as: ServerInternal
  alias Helix.Test.Universe.NPC.Helper, as: NPCHelper
  alias Helix.Cache.Action.Cache, as: CacheAction
  alias Helix.Test.Cache.Helper, as: CacheHelper
  alias Helix.Cache.Internal.Builder, as: BuilderInternal
  alias Helix.Cache.Internal.Cache, as: CacheInternal
  alias Helix.Cache.Internal.Populate, as: PopulateInternal
  alias Helix.Cache.State.PurgeQueue, as: StatePurgeQueue

  setup do
    CacheHelper.cache_context()
  end

  def hit_everything(server_id) do
    {:hit, server1} = CacheInternal.direct_query(:server, server_id)

    storage1_id = Enum.random(server1.storages)
    {:hit, storage1} = CacheInternal.direct_query(:storage, storage1_id)

    component1_id = Enum.random(server1.components)
    {:hit, component1} = CacheInternal.direct_query(:component, component1_id)

    {:hit, motherboard1} = CacheInternal.direct_query(
      :component,
      server1.motherboard_id)

    net1 = Enum.random(server1.networks)
    args = {net1["network_id"], net1["ip"]}
    {:hit, nip1} = CacheInternal.direct_query(:network, args)

    {server1, storage1, component1, motherboard1, nip1}
  end

  def assert_expiration_updated(data1, data2) do
    assert data1.expiration_date != data2.expiration_date
  end

  describe "update_server/1" do
    test "it works", context do
      server_id = context.server.server_id

      {:ok, server} = PopulateInternal.populate(:by_server, server_id)

      {server1, storage1, component1, mobo1, nip1} = hit_everything(server_id)

      # Update
      CacheAction.update_server(server_id)

      # While it's not yet synced, we need to ensure all related entries
      # are saved on the PurgeQueue
      assert StatePurgeQueue.lookup(:server, server_id)
      assert StatePurgeQueue.lookup(:component, server.motherboard_id)
      Enum.each(server.components, fn(component_id) ->
        assert StatePurgeQueue.lookup(:component, component_id)
      end)
      Enum.each(server.storages, fn(storage_id) ->
        assert StatePurgeQueue.lookup(:storage, storage_id)
      end)
      Enum.each(server.networks, fn(net) ->
        args = {to_string(net.network_id), net.ip}
        assert StatePurgeQueue.lookup(:network, args)
      end)

      # Sync
      StatePurgeQueue.sync()

      # After the sync, stuff on DB has been changed
      {server2, storage2, component2, mobo2, nip2} = hit_everything(server_id)

      assert_expiration_updated(server1, server2)
      assert_expiration_updated(storage1, storage2)
      assert_expiration_updated(component1, component2)
      assert_expiration_updated(mobo1, mobo2)
      assert_expiration_updated(nip1, nip2)

      CacheHelper.sync_test()
    end

    test "it works when motherboard is nil", context do
      server_id = context.server.server_id
      motherboard_id = context.server.motherboard_id

      PopulateInternal.populate(:by_server, server_id)

      # Detach mobo. This function will call its own update_server
      ServerInternal.detach(context.server)
      StatePurgeQueue.sync()

      # Cache has been populated after detach
      {:hit, server} = CacheInternal.direct_query(:server, server_id)

      # Populated entry already has empty motherboard
      assert_id server.server_id, server_id
      assert server.entity_id
      refute server.motherboard_id

      # Update
      CacheAction.update_server(server_id)

      # It only invalidates the server
      assert StatePurgeQueue.lookup(:server, server_id)
      refute StatePurgeQueue.lookup(:component, motherboard_id)

      # Sync
      StatePurgeQueue.sync()

      {:hit, server2} = CacheInternal.direct_query(:server, server_id)
      assert_id server2.server_id, server_id
      assert server2.entity_id
      refute server2.motherboard_id

      CacheHelper.sync_test()
    end
  end

  describe "update_server_by_motherboard/1" do
    test "it does nothing when cached data doesn't exists", context do
      server_id = context.server.server_id
      motherboard_id = context.server.motherboard_id

      CacheAction.update_server_by_motherboard(motherboard_id)

      refute StatePurgeQueue.lookup(:server, server_id)
    end
  end

  describe "update_storage/1" do
    test "storage is updated", context do
      server_id = context.server.server_id

      PopulateInternal.populate(:by_server, server_id)

      {server1, storage1, component1, mobo1, nip1} = hit_everything(server_id)

      storage_id = Enum.random(server1.storages)
      CacheAction.update_storage(storage_id)

      assert StatePurgeQueue.lookup(:server, server_id)
      assert StatePurgeQueue.lookup(:storage, storage_id)
      assert StatePurgeQueue.lookup(:component, mobo1.motherboard_id)
      Enum.each(server1.components, fn(component_id) ->
        assert StatePurgeQueue.lookup(:component, component_id)
      end)
      assert StatePurgeQueue.lookup(:network, {nip1.network_id, nip1.ip})

      StatePurgeQueue.sync()

      {server2, storage2, component2, mobo2, nip2} = hit_everything(server_id)

      assert_expiration_updated(server1, server2)
      assert_expiration_updated(storage1, storage2)
      assert_expiration_updated(component1, component2)
      assert_expiration_updated(mobo1, mobo2)
      assert_expiration_updated(nip1, nip2)

      CacheHelper.sync_test()
    end
  end

  describe "update_component/1" do
    test "it works", context do
      server_id = context.server.server_id

      PopulateInternal.populate(:by_server, server_id)

      {server1, storage1, component1, mobo1, nip1} = hit_everything(server_id)

      component_id = Enum.random(server1.components)
      CacheAction.update_component(component_id)

      assert StatePurgeQueue.lookup(:server, server_id)
      assert StatePurgeQueue.lookup(:storage, storage1.storage_id)
      assert StatePurgeQueue.lookup(:component, mobo1.motherboard_id)
      Enum.each(server1.components, fn(component_id) ->
        assert StatePurgeQueue.lookup(:component, component_id)
      end)
      assert StatePurgeQueue.lookup(:network, {nip1.network_id, nip1.ip})

      StatePurgeQueue.sync()

      {server2, storage2, component2, mobo2, nip2} = hit_everything(server_id)

      assert_expiration_updated(server1, server2)
      assert_expiration_updated(storage1, storage2)
      assert_expiration_updated(component1, component2)
      assert_expiration_updated(mobo1, mobo2)
      assert_expiration_updated(nip1, nip2)

      CacheHelper.sync_test()
    end
  end

  describe "update_network/1" do
    test "network is updated", context do
      server_id = context.server.server_id

      PopulateInternal.populate(:by_server, server_id)

      {server1, storage1, component1, mobo1, nip1} = hit_everything(server_id)

      net = Enum.random(server1.networks)
      CacheAction.update_network(net["network_id"], net["ip"])

      assert StatePurgeQueue.lookup(:server, server_id)
      assert StatePurgeQueue.lookup(:storage, storage1.storage_id)
      assert StatePurgeQueue.lookup(:component, mobo1.motherboard_id)
      Enum.each(server1.components, fn(component_id) ->
        assert StatePurgeQueue.lookup(:component, component_id)
      end)
      assert StatePurgeQueue.lookup(:network, {nip1.network_id, nip1.ip})

      StatePurgeQueue.sync()

      {server2, storage2, component2, mobo2, nip2} = hit_everything(server_id)

      assert_expiration_updated(server1, server2)
      assert_expiration_updated(storage1, storage2)
      assert_expiration_updated(component1, component2)
      assert_expiration_updated(mobo1, mobo2)
      assert_expiration_updated(nip1, nip2)

      CacheHelper.sync_test()
    end
  end

  describe "purge_storage/1" do
    test "default case", context do
      server_id = context.server.server_id

      # Populate on the DB
      {:ok, server} = PopulateInternal.populate(:by_server, server_id)
      assert {:hit, _} = CacheInternal.direct_query(:server, server_id)

      storage_id = Enum.random(server.storages)

      CacheAction.purge_storage(storage_id)

      assert StatePurgeQueue.lookup(:storage, storage_id)
      refute StatePurgeQueue.lookup(:server, server_id)

      StatePurgeQueue.sync()

      assert_miss CacheInternal.direct_query(:storage, storage_id)

      # Note that purge_storage will only purge storage, not the server
      # It's up to the caller to also notify the server has changed,
      # usually through `update_server_by_storage`
      assert {:hit, _} = CacheInternal.direct_query(:server, server_id)
    end
  end

  describe "update_server_by_storage" do
    test "default case", context do
      server_id = context.server.server_id

      # Populate on the DB
      {:ok, server} = PopulateInternal.populate(:by_server, server_id)
      assert {:hit, _} = CacheInternal.direct_query(:server, server_id)
      storage_id = Enum.random(server.storages)

      refute StatePurgeQueue.lookup(:server, server_id)

      CacheAction.update_server_by_storage(storage_id)

      assert StatePurgeQueue.lookup(:server, server_id)
      assert StatePurgeQueue.lookup(:storage, storage_id)
      assert StatePurgeQueue.lookup(:component, Enum.random(server.components))

      StatePurgeQueue.sync()

      assert {:hit, server2} = CacheInternal.direct_query(:server, server_id)
      assert_id server2.server_id, server_id
    end

    test "default case (cold)", context do
      server_id = context.server.server_id

      # Populate on the DB
      {:ok, server} = BuilderInternal.by_server(server_id)
      storage_id = Enum.random(server.storages)

      CacheAction.update_server_by_storage(storage_id)

      # Essentially performs a noop
      refute StatePurgeQueue.lookup(:server, server_id)
      refute StatePurgeQueue.lookup(:storage, storage_id)
      refute StatePurgeQueue.lookup(:component, Enum.random(server.components))

      StatePurgeQueue.sync()

      assert_miss CacheInternal.direct_query(:server, server_id)
    end
  end

  describe "update_web/2" do
    test "default case" do
      {_, ip} = NPCHelper.download_center()
      nip = {"::", ip}

      # Ensure cache is hot
      {:ok, _} = PopulateInternal.populate(:web_by_nip, nip)
      web1 = assert_hit CacheInternal.direct_query({:web, :content}, nip)
      refute StatePurgeQueue.lookup(:web, nip)

      # Update
      CacheAction.update_web("::", ip)

      # It syncs
      assert StatePurgeQueue.lookup(:web, nip)
      StatePurgeQueue.sync()
      refute StatePurgeQueue.lookup(:web, nip)

      # Fresh entry from db
      web2 = assert_hit CacheInternal.direct_query({:web, :content}, nip)
      diff =
        DateTime.diff(web2.expiration_date, web1.expiration_date, :millisecond)

      assert diff > 0

      assert web2.content == web1.content
    end
  end

  describe "purge_web/2" do
    test "default case" do
      {_, ip} = NPCHelper.download_center()
      nip = {"::", ip}

      # Ensure it exists on DB
      {:ok, _} = PopulateInternal.populate(:web_by_nip, nip)
      assert_hit CacheInternal.direct_query({:web, :content}, nip)
      refute StatePurgeQueue.lookup(:web, nip)

      # Purge
      CacheAction.purge_web("::", ip)

      # Sync
      assert StatePurgeQueue.lookup(:web, nip)
      StatePurgeQueue.sync()
      refute StatePurgeQueue.lookup(:web, nip)

      # No longer on DB
      assert_miss CacheInternal.direct_query({:web, :content}, nip)
    end
  end
end
