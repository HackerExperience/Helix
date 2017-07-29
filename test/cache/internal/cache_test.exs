defmodule Helix.Cache.Internal.CacheTest do

  use Helix.Test.IntegrationCase

  alias HELL.TestHelper.Random
  alias Helix.Server.Action.Server, as: ServerAction
  alias Helix.Cache.Internal.Builder, as: BuilderInternal
  alias Helix.Cache.Internal.Cache, as: CacheInternal
  alias Helix.Cache.Internal.Populate, as: PopulateInternal
  alias Helix.Cache.Model.ServerCache
  alias Helix.Cache.Repo
  alias Helix.Cache.State.PurgeQueue, as: StatePurgeQueue

  setup do
    alias Helix.Account.Factory, as: AccountFactory
    alias Helix.Account.Action.Flow.Account, as: AccountFlow

    account = AccountFactory.insert(:account)
    {:ok, %{server: server}} = AccountFlow.setup_account(account)
    :timer.sleep(50)

    alias Helix.Cache.Action.Cache, as: CacheAction
    CacheAction.purge_server(server.server_id)
    :timer.sleep(50)

    {:ok, account: account, server: server}
  end

  describe "lookup/2" do
    test "populates data after miss", context do
      server_id = context.server.server_id

      {:ok, origin} = BuilderInternal.by_server(server_id)

      {:ok, result} = CacheInternal.lookup({:server, :nips}, server_id)

      assert result == origin.networks

      :timer.sleep(10)
    end

    test "returns cached data", context do
      server_id = context.server.server_id

      {:ok, origin} = BuilderInternal.by_server(server_id)
      storage_id = List.first(origin.storages)

      # Insert directly into cache
      {:ok, cached} = PopulateInternal.populate(:by_server, server_id)

      {:ok, result} = CacheInternal.lookup({:server, :storages}, server_id)

      assert result == cached.storages
      assert result == [storage_id]

      :timer.sleep(10)
    end

    test "fails on invalid data"  do
      {:error, _} = CacheInternal.lookup({:server, :resources}, Random.pk())
    end

    test "returns valid but empty data", context do
      server_id = context.server.server_id

      ServerAction.detach(context.server)
      {:ok, storage} = CacheInternal.lookup({:server, :storages}, server_id)

      assert storage == nil

      :timer.sleep(10)
    end

    test "filters out expired entries", context do
      server_id = context.server.server_id

      {:ok, server} = PopulateInternal.populate(:by_server, server_id)
      :timer.sleep(10)

      expired_date =
        DateTime.utc_now()
        |> DateTime.to_unix(:second)
        |> Kernel.-(1)
        |> Ecto.DateTime.from_unix!(:second)

      {:ok, _} = ServerCache.create_changeset(server)
      |> Ecto.Changeset.force_change(:expiration_date, expired_date)
      |> Repo.insert(on_conflict: :replace_all, conflict_target: [:server_id])

      :miss = CacheInternal.direct_query(:server, server_id)

      :timer.sleep(100)
    end

    test "repopulates expired entries", context do
      server_id = context.server.server_id

      {:ok, server} = PopulateInternal.populate(:by_server, server_id)
      :timer.sleep(10)

      expired_date =
        DateTime.utc_now()
        |> DateTime.to_unix(:second)
        |> Kernel.-(1)
        |> Ecto.DateTime.from_unix!(:second)

      {:ok, _} = ServerCache.create_changeset(server)
      |> Ecto.Changeset.force_change(:expiration_date, expired_date)
      |> Repo.insert(on_conflict: :replace_all, conflict_target: [:server_id])

      :miss = CacheInternal.direct_query(:server, server_id)

      # CacheInternal.lookup/2 will populate non-existing entries
      {:ok, _} = CacheInternal.lookup({:server, :nips}, server_id)
      :timer.sleep(10)

      {:hit, server2} = CacheInternal.direct_query(:server, server_id)

      assert server2.server_id == server_id
      assert server2.expiration_date > expired_date

      :timer.sleep(10)
    end

    test "full (entire row) lookups", context do
      server_id = context.server.server_id

      {:ok, _} = PopulateInternal.populate(:by_server, server_id)

      {:ok, cserver} = CacheInternal.lookup(:server, server_id)

      assert is_map(cserver)
      assert cserver.server_id == server_id

      # Below is to ensure nested maps have atom indexes
      nip = List.first(cserver.networks)
      assert is_binary(nip.ip)

      :timer.sleep(10)
    end
  end

  # Purging and updating at CacheInternal is asynchronous (except for PurgeQueue
  # notification, which is synchronous)
  describe "purge/2" do
    test "purge queue", context do
      server_id = context.server.server_id

      {:ok, server} = PopulateInternal.populate(:by_server, server_id)
      :timer.sleep(20)

      storage_id = List.first(server.storages)

      refute StatePurgeQueue.lookup(:storage, storage_id)

      CacheInternal.purge(:storage, storage_id)

      assert StatePurgeQueue.lookup(:storage, storage_id)

      # Sync
      :timer.sleep(20)

      :miss = CacheInternal.direct_query(:storage, storage_id)

      refute StatePurgeQueue.lookup(:storage, storage_id)

      :timer.sleep(10)
    end
  end
end
