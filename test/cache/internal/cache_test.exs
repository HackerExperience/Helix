defmodule Helix.Cache.Internal.CacheTest do

  use Helix.Test.IntegrationCase

  alias HELL.TestHelper.Random
  alias Helix.Server.Action.Server, as: ServerAction
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Hardware.Query.Motherboard, as: MotherboardQuery
  alias Helix.Cache.Model.ServerCache
  alias Helix.Cache.Internal.Cache, as: CacheInternal
  alias Helix.Cache.Internal.Populate, as: PopulateInternal
  alias Helix.Cache.Repo

  setup do
    alias Helix.Account.Factory, as: AccountFactory
    alias Helix.Account.Action.Flow.Account, as: AccountFlow

    account = AccountFactory.insert(:account)
    {:ok, %{server: server}} = AccountFlow.setup_account(account)

    {:ok, account: account, server: server}
  end

  describe "lookup/2" do
    test "populates data after miss", context do
      server_id = context.server.server_id

      {:ok, result} = CacheInternal.lookup({:server, :nips}, [server_id])

      assert result == ServerQuery.get_nips(server_id)

      :timer.sleep(10)
    end

    test "returns cached data", context do
      server_id = context.server.server_id
      motherboard_id = context.server.motherboard_id
      storages = MotherboardQuery.get_storages(motherboard_id)

      # Insert directly into cache
      {:ok, cached} = PopulateInternal.populate(:server, server_id)

      {:ok, result} = CacheInternal.lookup({:server, :storages}, [server_id])

      assert result == cached.storages
      assert result == [storages.storage_id]

      :timer.sleep(10)
    end

    test "fails on invalid data"  do
      {:error, _} = CacheInternal.lookup({:server, :resources}, [Random.pk()])
    end

    test "returns valid but empty data", context do
      server_id = context.server.server_id

      ServerAction.detach(context.server)
      {:ok, storage} = CacheInternal.lookup({:server, :storages}, [server_id])

      assert storage == nil

      :timer.sleep(10)
    end

    test "filters out expired entries", context do
      server_id = context.server.server_id

      {:ok, server} = PopulateInternal.populate(:server, server_id)
      :timer.sleep(10)

      expired_date = Ecto.DateTime.from_unix!(DateTime.to_unix(DateTime.utc_now()) - 600000, :second)

      {:ok, _} = ServerCache.create_changeset(server)
      |> Ecto.Changeset.force_change(:expiration_date, expired_date)
      |> Repo.insert(on_conflict: :replace_all, conflict_target: [:server_id])

      :miss = CacheInternal.direct_query(:server, server_id)

      :timer.sleep(10)
    end

    test "repopulates expired entries", context do
      server_id = context.server.server_id

      {:ok, server} = PopulateInternal.populate(:server, server_id)
      :timer.sleep(10)

      expired_date = Ecto.DateTime.from_unix!(DateTime.to_unix(DateTime.utc_now()) - 600000, :second)

      {:ok, _} = ServerCache.create_changeset(server)
      |> Ecto.Changeset.force_change(:expiration_date, expired_date)
      |> Repo.insert(on_conflict: :replace_all, conflict_target: [:server_id])

      :miss = CacheInternal.direct_query(:server, server_id)

      {:ok, _} = CacheInternal.lookup({:server, :nips}, [server_id])
      :timer.sleep(10)

      {:hit, server2} = CacheInternal.direct_query(:server, server_id)

      assert server2.server_id == server_id
      assert server2.expiration_date > expired_date

      :timer.sleep(10)
    end

    test "full (entire row) lookups", context do
      server_id = context.server.server_id

      {:ok, _} = PopulateInternal.populate(:server, server_id)

      {:ok, cserver} = CacheInternal.lookup(:server, [server_id])

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

      {:ok, server} = PopulateInternal.populate(:server, server_id)
      :timer.sleep(20)

      storage_id = List.first(server.storages)

      refute CacheInternal.is_marked_as_purged(:storage, storage_id)

      CacheInternal.purge(:storage, storage_id)

      assert CacheInternal.is_marked_as_purged(:storage, storage_id)

      # Sync
      :timer.sleep(20)

      :miss = CacheInternal.direct_query(:storage, storage_id)

      refute CacheInternal.is_marked_as_purged(:storage, storage_id)

      :timer.sleep(10)
    end
  end
end
