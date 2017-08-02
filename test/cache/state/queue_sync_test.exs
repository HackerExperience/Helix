defmodule Helix.Cache.State.QueueSyncTest do

  use Helix.Test.IntegrationCase

  alias Helix.Cache.Helper, as: CacheHelper
  alias Helix.Cache.Internal.Cache, as: CacheInternal
  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Cache.State.PurgeQueue, as: StatePurgeQueue
  alias Helix.Cache.State.QueueSync, as: StateQueueSync

  setup do
    CacheHelper.cache_context()
  end

  describe "queue sync" do
    test "it syncs periodically", context do
      server_id = context.server.server_id

      # Set QueueSync interval to 1s
      StateQueueSync.set_interval(1000)

      # First query, will fetch from origin and add entry to PurgeQueue
      {:ok, server} = CacheQuery.from_server_get_all(server_id)
      refute Map.has_key?(server, :expiration_date)
      assert StatePurgeQueue.lookup(:server, server_id)

      # Nothing on the DB..
      :miss = CacheInternal.direct_query(:server, server_id)

      # But once we give it enough time to sync...
      :timer.sleep(1100)

      # ...it will be added to the DB
      {:hit, _} = CacheInternal.direct_query(:server, server_id)
      {:ok, server} = CacheQuery.from_server_get_all(server_id)
      assert server.expiration_date

      # And removed from the PurgeQueue
      refute StatePurgeQueue.lookup(:server, server_id)

      StatePurgeQueue.sync()
    end
  end
end
