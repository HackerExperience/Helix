defmodule Helix.Cache.State.QueueSyncTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Case.Cache

  alias Helix.Test.Cache.Helper, as: CacheHelper
  alias Helix.Cache.Internal.Cache, as: CacheInternal
  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Cache.State.PurgeQueue, as: StatePurgeQueue

  setup do
    CacheHelper.cache_context()
  end

  describe "queue sync" do
    test "it syncs periodically", context do
      server_id = context.server.server_id

      # First query, will fetch from origin and add entry to PurgeQueue
      {:ok, _} = CacheQuery.from_server_get_all(server_id)
      assert_miss CacheInternal.direct_query(:server, server_id)
      assert StatePurgeQueue.lookup(:server, server_id)

      # Nothing on the DB..
      assert_miss CacheInternal.direct_query(:server, server_id)

      # Simulate QueueSync receiving a `:sync` message after timer is triggered
      Kernel.send(:cache_queue_sync, :sync)
      :timer.sleep(50)

      # ...it will be added to the DB
      assert_hit CacheInternal.direct_query(:server, server_id)
      {:ok, _} = CacheQuery.from_server_get_all(server_id)

      # And removed from the PurgeQueue
      refute StatePurgeQueue.lookup(:server, server_id)

      StatePurgeQueue.sync()
    end
  end
end
