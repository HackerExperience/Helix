defmodule Helix.Cache.Query.CacheTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Case.Cache
  import Helix.Test.Case.ID

  alias Helix.Test.Universe.NPC.Helper, as: NPCHelper
  alias Helix.Cache.Action.Cache, as: CacheAction
  alias Helix.Test.Cache.Helper, as: CacheHelper
  alias Helix.Cache.Internal.Cache, as: CacheInternal
  alias Helix.Cache.Internal.Populate, as: PopulateInternal
  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Cache.State.PurgeQueue, as: StatePurgeQueue

  setup do
    CacheHelper.cache_context
  end

  describe "query" do
    test "it is alive", context do
      server_id = context.server.server_id

      {:ok, server} = CacheQuery.from_server_get_all(server_id)

      assert server.server_id == server_id

      CacheHelper.sync_test()
    end

    test "it automatically populates the db", context do
      server_id = context.server.server_id

      {:ok, _} = CacheQuery.from_server_get_all(server_id)

      StatePurgeQueue.sync()

      {:hit, server} = CacheInternal.direct_query(:server, server_id)

      assert_id server.server_id, server_id

      CacheHelper.sync_test()
    end

    test "it won't repopulate if valid entry exists", context do
      server_id = context.server.server_id

      refute StatePurgeQueue.lookup(:server, server_id)

      # Query for first time
      {:ok, _} = CacheQuery.from_server_get_nips(server_id)

      # It is listed as purged, being populated
      assert StatePurgeQueue.lookup(:server, server_id)

      StatePurgeQueue.sync()

      # Entry has been populated. No longer on purge queue.
      {:hit, _} = CacheInternal.direct_query(:server, server_id)
      refute StatePurgeQueue.lookup(:server, server_id)

      # Query for second time
      # Must not be added to the purge queue. If it was, then it is populating
      # again, which is unexpected.
      {:ok, _} = CacheQuery.from_server_get_nips(server_id)
      refute StatePurgeQueue.lookup(:server, server_id)
      {:hit, _} = CacheInternal.direct_query(:server, server_id)

      CacheHelper.sync_test()
    end
  end

  describe "queue synchronization on updates" do
    test "builds from origin when data is marked as purged", context do
      server_id = context.server.server_id

      refute StatePurgeQueue.lookup(:server, server_id)

      # Ensure server *exists* on the Cache. Otherwise, invalidating it wouldn't
      # trigger a purge/update call
      {:ok, _server} = PopulateInternal.populate(:by_server, server_id)

      # Start invalidation action
      CacheAction.update_server(server_id)

      # Hasn't synced yet
      assert StatePurgeQueue.lookup(:server, server_id)

      # But querying it returns the row correctly
      {:ok, server1} = CacheQuery.from_server_get_all(server_id)

      # Different times!
      {:ok, server2} = CacheQuery.from_server_get_all(server_id)
      {:ok, server3} = CacheQuery.from_server_get_all(server_id)

      # Those are actually different values, not from the cache
      # (because the entry is still marked as purged)
      refute Map.has_key?(server1, :expiration_date)
      refute Map.has_key?(server2, :expiration_date)
      refute Map.has_key?(server3, :expiration_date)

      # But if we do sync it...
      StatePurgeQueue.sync()

      # ...the next query comes from the Cache
      assert_hit CacheInternal.direct_query(:server, server_id)
      assert {:ok, _} = CacheQuery.from_server_get_all(server_id)

      # And it's no longer on the purge queue
      refute StatePurgeQueue.lookup(:server, server_id)

      CacheHelper.sync_test()
    end
    test "builds from origin when data is marked as purged (cold)", context do
      server_id = context.server.server_id

      refute StatePurgeQueue.lookup(:server, server_id)

      # Start invalidation action
      CacheAction.update_server(server_id)

      # Server isn't added to PurgeQueue because it never existed on the cache
      refute StatePurgeQueue.lookup(:server, server_id)

      # Hasn't synced yet
      assert_miss CacheInternal.direct_query(:server, server_id)

      # But querying it returns the row correctly
      {:ok, _} = CacheQuery.from_server_get_all(server_id)

      # Different times!
      {:ok, _} = CacheQuery.from_server_get_all(server_id)
      {:ok, _} = CacheQuery.from_server_get_all(server_id)

      # Those are actually different values, not from the cache
      # (because the entry is still marked as purged)
      assert_miss CacheInternal.direct_query(:server, server_id)

      # But if we do sync it...
      StatePurgeQueue.sync()

      # ...the next query comes from the Cache
      assert_hit CacheInternal.direct_query(:server, server_id)
      assert {:ok, _} = CacheQuery.from_server_get_all(server_id)

      # And it's no longer on the purge queue
      refute StatePurgeQueue.lookup(:server, server_id)

      CacheHelper.sync_test()
    end
  end

  describe "queue synchronization on purges" do
    test "sync is transparent", context do
      server_id = context.server.server_id

      refute StatePurgeQueue.lookup(:server, server_id)
      {:ok, server} = PopulateInternal.populate(:by_server, server_id)

      motherboard_id = server.motherboard_id
      component_id = Enum.random(server.components)
      nip = Enum.random(server.networks)
      storage_id = Enum.random(server.storages)

      # Purge
      CacheAction.purge_component(component_id)

      # Component is marked for deletion...
      assert StatePurgeQueue.lookup(:component, component_id)

      # But his buddies aren't
      refute StatePurgeQueue.lookup(:server, server_id)
      refute StatePurgeQueue.lookup(:component, motherboard_id)
      refute StatePurgeQueue.lookup(:storage, storage_id)
      refute StatePurgeQueue.lookup(:network, {nip.network_id, nip.ip})

      # Hasn't synced yet, so we can still query it directly...
      assert {:hit, _} = CacheInternal.direct_query(:component, component_id)

      # Querying it TheRightWay will return a brand new result
      # (note that it's not this test's purpose to verify the result is, in
      # fact, brand new)
      assert {:ok, _} = CacheQuery.from_component_get_motherboard(component_id)

      # Because it is still marked for deletion
      assert StatePurgeQueue.lookup(:component, component_id)

      CacheHelper.sync_test()
    end
  end

  describe "from_nip_get_web/2" do
    test "returns content belonging to nip" do
      {_, ip} = NPCHelper.download_center()
      nip = {"::", ip}

      # Ensure it is already cached
      {:ok, _} = PopulateInternal.populate(:web_by_nip, nip)
      assert_hit CacheInternal.direct_query({:web, :content}, nip)

      assert {:ok, content} = CacheQuery.from_nip_get_web("::", ip)
      assert content.title

      refute StatePurgeQueue.lookup(:web, nip)

      CacheHelper.sync_test()
    end

    test "it works (cold)" do
      {_, ip} = NPCHelper.download_center()
      nip = {"::", ip}

      # Not cached
      assert_miss CacheInternal.direct_query({:web, :content}, nip)

      # Queries (from origin)
      assert {:ok, content} = CacheQuery.from_nip_get_web("::", ip)
      assert content.title

      # Marked as purged
      assert StatePurgeQueue.lookup(:web, nip)

      # Cached on sync
      StatePurgeQueue.sync()
      refute StatePurgeQueue.lookup(:web, nip)
      assert_hit CacheInternal.direct_query({:web, :content}, nip)
    end
  end
end
