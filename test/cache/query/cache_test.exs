defmodule Helix.Cache.Query.CacheTest do

  use Helix.Test.IntegrationCase

  alias Helix.Cache.Action.Cache, as: CacheAction
  alias Helix.Cache.Internal.Cache, as: CacheInternal
  alias Helix.Cache.Internal.Populate, as: PopulateInternal
  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Cache.State.PurgeQueue, as: StatePurgeQueue

  setup do
    alias Helix.Account.Factory, as: AccountFactory
    alias Helix.Account.Action.Flow.Account, as: AccountFlow

    account = AccountFactory.insert(:account)
    {:ok, %{server: server}} = AccountFlow.setup_account(account)

    {:ok, account: account, server: server}
  end

  describe "query" do
    test "it is alive", context do
      server_id = context.server.server_id

      {:ok, server} = CacheQuery.from_server_get_all(server_id)

      assert server.server_id == server_id

      :timer.sleep(10)
    end

    test "it automatically populates the db", context do
      server_id = context.server.server_id

      {:ok, _} = CacheQuery.from_server_get_all(server_id)

      # Wait for sync
      :timer.sleep(20)

      {:hit, server} = CacheInternal.direct_query(:server, server_id)

      assert server.server_id == server_id

      :timer.sleep(10)
    end

    test "it won't repopulate if valid entry exists", context do
      server_id = context.server.server_id

      refute StatePurgeQueue.lookup(:server, [server_id])

      # Query for first time
      {:ok, _} = CacheQuery.from_server_get_nips(server_id)

      # It is listed as purged, being populated
      assert StatePurgeQueue.lookup(:server, [server_id])
      :timer.sleep(50)

      # Entry has been populated. No longer on purge queue.
      {:hit, _} = CacheInternal.direct_query(:server, [server_id])
      refute StatePurgeQueue.lookup(:server, [server_id])

      # Query for second time
      # Must not be added to the purge queue. If it was, then it is populating
      # again, which is unexpected.
      {:ok, _} = CacheQuery.from_server_get_nips(server_id)
      refute StatePurgeQueue.lookup(:server, [server_id])
      {:hit, _} = CacheInternal.direct_query(:server, [server_id])

      :timer.sleep(100)
    end
  end

  describe "queue synchronization on updates" do
    test "sync is transparent", context do
      server_id = context.server.server_id

      refute StatePurgeQueue.lookup(:server, server_id)

      # Start invalidation action
      CacheAction.update_server(server_id)

      assert StatePurgeQueue.lookup(:server, server_id)

      # Hasn't synced yet
      :miss = CacheInternal.direct_query(:server, server_id)

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

      :timer.sleep(10)

      # Eventually removes from the purge queue
      refute StatePurgeQueue.lookup(:server, server_id)

      :timer.sleep(10)
    end

    test "sync is transparent on side-population1", context do
      # On this test (split in two parts), we:
      # 1) populate server, leading to side-population
      # 2) ensure everything is marked as purged (test1)
      # 3) ensure there's nothing on DB yet (test1)
      # 4) while we have nothing, synchronously query storage (test2)
      # 5) ensure storage is no longer marked as purged (test2)
      # all of this while the original side-population hasn't finished yet,
      # because motherboard_id is still marked as purged (test2).

      server_id = context.server.server_id

      {:ok, server} = PopulateInternal.populate(:server, server_id)

      storage_id = List.first(server.storages)
      component_id = List.first(server.components)
      motherboard_id = server.motherboard_id
      nip = List.first(server.networks)

      assert StatePurgeQueue.lookup(:server, server_id)
      assert StatePurgeQueue.lookup(:storage, storage_id)
      assert StatePurgeQueue.lookup(:component, component_id)
      assert StatePurgeQueue.lookup(:component, motherboard_id)
      assert StatePurgeQueue.lookup(:network, [nip.network_id, nip.ip])

      # Note: By now we've probably already have `server` inserted at the DB
      # Therefore, we'll use as test subject motherboard_id, because it's the
      # last to be inserted on side-population

      :miss = CacheInternal.direct_query(:storage, storage_id)
      :miss = CacheInternal.direct_query(:component, motherboard_id)

      {:ok, _} = CacheQuery.from_component_get_motherboard(motherboard_id)

      refute StatePurgeQueue.lookup(:component, motherboard_id)

      # Continues on test below

      :timer.sleep(10)
    end

    test "sync is transparent on side-population2", context do
      # The reason we have to split this test is two is because of its
      # time sensitivity. While looking up for all purged components above
      # (using `is_marked_as_purged/2`), we gave enough time for `populate/2`
      # to finish side-populating everything.
      # On this new test, we redo the population step without the extra lookups
      # This gives us time to create a mini race condition (described on test1)
      server_id = context.server.server_id
      motherboard_id = context.server.motherboard_id

      {:ok, server} = PopulateInternal.populate(:server, server_id)
      storage_id = List.first(server.storages)

      {:ok, _} = CacheQuery.from_storage_get_server(storage_id)

      refute StatePurgeQueue.lookup(:storage, storage_id)
      assert StatePurgeQueue.lookup(:component, motherboard_id)

      :timer.sleep(10)
    end
  end

  describe "queue synchronization on purges" do
    test "sync is transparent1", context do
      server_id = context.server.server_id

      refute StatePurgeQueue.lookup(:server, server_id)
      {:ok, server} = PopulateInternal.populate(:server, server_id)
      :timer.sleep(20)

      motherboard_id = server.motherboard_id
      component_id = List.first(server.components)
      nip = List.first(server.networks)
      storage_id = List.first(server.storages)

      # Purge
      CacheAction.purge_component(component_id)

      # Component is marked for deletion...
      assert StatePurgeQueue.lookup(:component, component_id)

      # But his buddies aren't
      refute StatePurgeQueue.lookup(:server, server_id)
      refute StatePurgeQueue.lookup(:component, motherboard_id)
      refute StatePurgeQueue.lookup(:storage, storage_id)
      refute StatePurgeQueue.lookup(:network, [nip.network_id, nip.ip])

      # Continues below

      :timer.sleep(10)
    end

    test "sync is transparent2", context do
      # (Once again, part 2 is required to ensure correct timing for the test)
      server_id = context.server.server_id

      {:ok, server} = PopulateInternal.populate(:server, server_id)
      :timer.sleep(20)

      component_id = List.first(server.components)

      # Purge
      CacheAction.purge_component(component_id)

      # Hasn't synced yet, so we can still query it directly...
      {:hit, component} = CacheInternal.direct_query(:component, component_id)

      # But querying it TheRightWay will lead to re-population (and Queue sync)
      {:ok, _} = CacheQuery.from_component_get_motherboard(component_id)
      refute StatePurgeQueue.lookup(:component, component_id)

      # And here's the proof
      {:hit, component1} = CacheInternal.direct_query(:component, component_id)
      assert component1.expiration_date != component.expiration_date
      assert component1.motherboard_id == component.motherboard_id

      :timer.sleep(10)
    end
  end
end
