defmodule Helix.Cache.Internal.CacheTest do

  use Helix.Test.IntegrationCase

  import Helix.Test.CacheCase

  alias Helix.Server.Action.Server, as: ServerAction
  alias Helix.Server.Model.Server
  alias Helix.Cache.Helper, as: CacheHelper
  alias Helix.Cache.Internal.Builder, as: BuilderInternal
  alias Helix.Cache.Internal.Cache, as: CacheInternal
  alias Helix.Cache.Internal.Populate, as: PopulateInternal
  alias Helix.Cache.Model.ServerCache
  alias Helix.Cache.Repo
  alias Helix.Cache.State.PurgeQueue, as: StatePurgeQueue

  setup do
    CacheHelper.cache_context()
  end

  describe "lookup/2" do
    test "populates data after miss", context do
      server_id = context.server.server_id

      assert_miss CacheInternal.direct_query(:server, server_id)

      {:ok, origin} = BuilderInternal.by_server(server_id)

      {:ok, result} = CacheInternal.lookup({:server, :nips}, server_id)

      assert_id result, origin.networks

      CacheHelper.sync_test()
    end

    test "returns cached data", context do
      server_id = context.server.server_id

      # Ensure cache is empty
      assert_miss CacheInternal.direct_query(:server, server_id)

      # Insert directly into cache
      {:ok, cached} = PopulateInternal.populate(:by_server, server_id)

      # Ensures it came from the cache
      assert_hit CacheInternal.direct_query(:server, server_id)

      # External API (lookup) works as expected
      {:ok, result} = CacheInternal.lookup(:server, server_id)

      assert_id result.storages, cached.storages
      assert_id result.server_id, server_id

      CacheHelper.sync_test()
    end

    test "fails on invalid data"  do
      id = Server.ID.generate()
      {:error, _} = CacheInternal.lookup({:server, :resources}, id)
    end

    test "returns valid but empty data", context do
      server_id = context.server.server_id

      ServerAction.detach(context.server)
      {:ok, storage} = CacheInternal.lookup({:server, :storages}, server_id)

      assert storage == nil

      CacheHelper.sync_test()
    end

    test "filters out expired entries", context do
      server_id = context.server.server_id

      {:ok, server} = PopulateInternal.populate(:by_server, server_id)

      expired_date =
        DateTime.utc_now()
        |> DateTime.to_unix(:second)
        |> Kernel.-(1)
        |> Ecto.DateTime.from_unix!(:second)

      {:ok, _} =
        server
        |> ServerCache.create_changeset()
        |> Ecto.Changeset.force_change(:expiration_date, expired_date)
        |> Repo.insert(on_conflict: :replace_all, conflict_target: [:server_id])

      assert_miss CacheInternal.direct_query(:server, server_id)

      CacheHelper.sync_test()
    end

    test "repopulates expired entries", context do
      server_id = context.server.server_id

      {:ok, server} = PopulateInternal.populate(:by_server, server_id)
      StatePurgeQueue.sync()

      expired_date =
        DateTime.utc_now()
        |> DateTime.to_unix(:second)
        |> Kernel.-(1)
        |> DateTime.from_unix!(:second)

      server
      |> ServerCache.create_changeset()
      |> Ecto.Changeset.force_change(:expiration_date, expired_date)
      |> Repo.insert!(on_conflict: :replace_all, conflict_target: [:server_id])

      assert_miss CacheInternal.direct_query(:server, server_id)

      # CacheInternal.lookup/2 will populate non-existing entries
      {:ok, _} = CacheInternal.lookup({:server, :nips}, server_id)

      StatePurgeQueue.sync()

      {:hit, server2} = CacheInternal.direct_query(:server, server_id)

      assert_id server2.server_id, server_id
      assert server2.expiration_date > expired_date

      CacheHelper.sync_test()
    end

    test "full (entire row) lookups", context do
      server_id = context.server.server_id

      {:ok, _} = PopulateInternal.populate(:by_server, server_id)

      {:ok, cserver} = CacheInternal.lookup(:server, server_id)

      assert is_map(cserver)
      assert_id cserver.server_id, server_id

      # Below is to ensure nested maps have atom indexes
      nip = Enum.random(cserver.networks)
      assert is_binary(nip.ip)

      CacheHelper.sync_test()
    end
  end

  # Purging and updating at CacheInternal is asynchronous (except for PurgeQueue
  # notification, which is synchronous)
  describe "purge/2" do
    test "purge queue", context do
      server_id = context.server.server_id

      # Ensure the cache is empty
      refute StatePurgeQueue.lookup(:server, server_id)

      {:ok, server} = PopulateInternal.populate(:by_server, server_id)

      storage_id = Enum.random(server.storages)

      refute StatePurgeQueue.lookup(:storage, storage_id)

      CacheInternal.purge(:storage, to_string(storage_id))

      assert StatePurgeQueue.lookup(:storage, storage_id)

      StatePurgeQueue.sync()

      assert {:miss, :notfound} = CacheInternal.direct_query(
        :storage,
        storage_id)

      refute StatePurgeQueue.lookup(:storage, storage_id)

      CacheHelper.sync_test()
    end
  end
end
