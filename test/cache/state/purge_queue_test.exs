defmodule Helix.Cache.State.PurgeQueueTest do

  use Helix.Test.IntegrationCase

  alias Helix.Cache.Helper, as: CacheHelper
  alias Helix.Cache.Internal.Cache, as: CacheInternal
  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Cache.State.PurgeQueue, as: StatePurgeQueue

  setup do
    CacheHelper.cache_context()
  end

  # Look mah, no sleeps!
  describe "queue synchronization" do
    test "it syncs!", context do
      server_id = context.server.server_id

      {:ok, _} = CacheQuery.from_server_get_all(server_id)

      # It is waiting for synchronization
      assert StatePurgeQueue.lookup(:server, server_id)

      # Definitely not on the db
      assert :miss = CacheInternal.direct_query(:server, server_id)

      StatePurgeQueue.sync()

      # It's alive!
      assert {:hit, _} = CacheInternal.direct_query(:server, server_id)

      # And no longer on the PurgeQueue
      refute StatePurgeQueue.lookup(:server, server_id)

      CacheHelper.sync_test()
    end

    test "syncing server and all its buddies", context do
      server_id = context.server.server_id

      {:ok, server} = CacheQuery.from_server_get_all(server_id)

      # Data did not came from cache
      refute Map.has_key?(server, :expiration_date)

      storage_id = List.first(server.storages)
      component_id = List.first(server.components)
      motherboard_id = server.motherboard_id
      nip = List.first(server.networks)

      assert StatePurgeQueue.lookup(:server, server_id)
      assert StatePurgeQueue.lookup(:storage, storage_id)
      assert StatePurgeQueue.lookup(:component, component_id)
      assert StatePurgeQueue.lookup(:component, motherboard_id)
      assert StatePurgeQueue.lookup(:network, {nip.network_id, nip.ip})

      assert :miss = CacheInternal.direct_query(:server, server_id)
      assert :miss = CacheInternal.direct_query(:network, {nip.network_id, nip.ip})
      assert :miss = CacheInternal.direct_query(:storage, storage_id)
      assert :miss = CacheInternal.direct_query(:component, motherboard_id)

      StatePurgeQueue.sync()

      assert {:ok, server} = CacheQuery.from_server_get_all(server_id)

      # Data came from cache
      assert server.expiration_date

      # No longer on PurgeQueue
      refute StatePurgeQueue.lookup(:component, motherboard_id)

      CacheHelper.sync_test()
    end
  end
end
