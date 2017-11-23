defmodule Helix.Cache.Integration.Server.ServerTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Case.Cache
  import Helix.Test.Case.ID

  alias Helix.Server.Internal.Server, as: ServerInternal
  alias Helix.Test.Cache.Helper, as: CacheHelper
  alias Helix.Cache.Internal.Builder, as: BuilderInternal
  alias Helix.Cache.Internal.Cache, as: CacheInternal
  alias Helix.Cache.Internal.Populate, as: PopulateInternal
  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Cache.State.PurgeQueue, as: StatePurgeQueue

  setup do
    CacheHelper.cache_context()
  end

  describe "server integration" do

    test "attach motherboard updates cache", context do
      server_id = context.server.server_id
      motherboard_id = context.server.motherboard_id

      StatePurgeQueue.sync()

      # Make sure it exists on cache, else CacheAction simply ignores the fact
      # that the server/motherboard changed.
      PopulateInternal.populate(:by_server, server_id)

      # Not marked for update
      refute StatePurgeQueue.lookup(:server, server_id)

      assert {:ok, _} = ServerInternal.attach(context.server, motherboard_id)

      # Marked for update
      assert StatePurgeQueue.lookup(:server, server_id)

      StatePurgeQueue.sync()

      assert {:hit, server} = CacheInternal.direct_query(:server, server_id)

      assert_id server.server_id, server_id
      assert server.storages
      assert server.networks

      refute StatePurgeQueue.lookup(:server, server_id)

      CacheHelper.sync_test()
    end

    test "detach motherboard cleans cache", context do
      server_id = context.server.server_id

      {:ok, server} = PopulateInternal.populate(:by_server, server_id)

      {:hit, _} = CacheInternal.direct_query(:server, server_id)

      refute StatePurgeQueue.lookup(:server, server_id)

      ServerInternal.detach(context.server)

      assert StatePurgeQueue.lookup(:server, server_id)

      StatePurgeQueue.sync()

      assert {:hit, server} = CacheInternal.direct_query(:server, server_id)

      assert_id server.server_id, server_id
      assert Enum.empty?(server.storages)
      assert Enum.empty?(server.networks)

      CacheHelper.sync_test()
    end

    test "detach motherboard cleans cache (cold)", context do
      server_id = context.server.server_id

      {:ok, server} = BuilderInternal.by_server(server_id)

      refute StatePurgeQueue.lookup(:server, server_id)

      ServerInternal.detach(context.server)

      refute StatePurgeQueue.lookup(:server, server_id)

      CacheHelper.sync_test()
    end

    test "deleting server cleans cache", context do
      server_id = context.server.server_id

      {:ok, server} = PopulateInternal.populate(:by_server, server_id)

      nip = Enum.random(server.networks)

      refute StatePurgeQueue.lookup(:server, server_id)

      ServerInternal.delete(context.server)

      assert StatePurgeQueue.lookup(:server, server_id)
      Enum.each(server.storages, fn(storage_id) ->
        assert StatePurgeQueue.lookup(:storage, storage_id)
      end)
      nip_args = {to_string(nip.network_id), nip.ip}
      assert StatePurgeQueue.lookup(:network, nip_args)

      StatePurgeQueue.sync()

      assert {:error, reason} = CacheQuery.from_server_get_all(server_id)
      assert reason == {:server, :notfound}

      CacheHelper.sync_test()
    end

    test "deleting server cleans cache (cold)", context do
      server_id = context.server.server_id

      {:ok, server} = BuilderInternal.by_server(server_id)

      nip = Enum.random(server.networks)

      refute StatePurgeQueue.lookup(:server, server_id)

      ServerInternal.delete(context.server)

      # Nothing to delete...
      refute StatePurgeQueue.lookup(:server, server_id)
      Enum.each(server.storages, fn(storage_id) ->
        refute StatePurgeQueue.lookup(:storage, storage_id)
      end)
      refute StatePurgeQueue.lookup(:network, {nip.network_id, nip.ip})

      StatePurgeQueue.sync()

      assert {:error, reason} = CacheQuery.from_server_get_all(server_id)
      assert reason == {:server, :notfound}

      CacheHelper.sync_test()
    end
  end
end
