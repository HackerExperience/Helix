defmodule Helix.Cache.Internal.PurgeTest do

  use Helix.Test.IntegrationCase

  alias HELL.TestHelper.Random
  alias Helix.Cache.Internal.Cache, as: CacheInternal
  alias Helix.Cache.Internal.Populate, as: PopulateInternal
  alias Helix.Cache.Internal.Purge, as: PurgeInternal
  alias Helix.Cache.Model.ServerCache
  alias Helix.Cache.Repo

  setup do
    alias Helix.Account.Factory, as: AccountFactory
    alias Helix.Account.Action.Flow.Account, as: AccountFlow

    account = AccountFactory.insert(:account)
    {:ok, %{server: server}} = AccountFlow.setup_account(account)

    {:ok, account: account, server: server}
  end

  def direct_cache_query(server_id) do
    ServerCache.Query.by_server(server_id)
    |> Repo.one
  end

  describe "purge/2" do
    test "existing data is purged", context do
      server_id = context.server.server_id

      {:ok, _} = PopulateInternal.populate(:server, server_id)

      {:hit, _} = CacheInternal.direct_query(:server, server_id)

      PurgeInternal.purge(:server, server_id)

      assert :miss == CacheInternal.direct_query(:server, server_id)

      :timer.sleep(10)
    end

    test "purge is indepmtotente", context do
      server_id = context.server.server_id

      {:ok, _} = PopulateInternal.populate(:server, server_id)

      {:hit, _} = CacheInternal.direct_query(:server, server_id)

      PurgeInternal.purge(:server, server_id)
      PurgeInternal.purge(:server, server_id)
      PurgeInternal.purge(:server, server_id)

      assert :miss == CacheInternal.direct_query(:server, server_id)

      :timer.sleep(10)
    end

    test "issues a noop on non-existing data"  do
      assert :nocache == PurgeInternal.purge(:server, Random.pk())
    end
  end

  describe "purge logic" do
    test "purging server deletes everything", context do
      server_id = context.server.server_id

      {:ok, [nip]} = CacheInternal.lookup({:server, :nips}, [server_id])
      {:ok, [storage_id]} = CacheInternal.lookup({:server, :storages}, [server_id])
      {:ok, components} = CacheInternal.lookup({:server, :components}, [server_id])

      PurgeInternal.purge(:server, server_id)

      :miss = CacheInternal.direct_query(:server, server_id)
      :miss = CacheInternal.direct_query(:storage, storage_id)
      :miss = CacheInternal.direct_query(:component, List.first(components))
      :miss = CacheInternal.direct_query(:network, [nip.network_id, nip.ip])

      :timer.sleep(10)
    end

    test "purging storage deletes everything", context do
      server_id = context.server.server_id

      {:ok, [nip]} = CacheInternal.lookup({:server, :nips}, [server_id])
      {:ok, [storage_id]} = CacheInternal.lookup({:server, :storages}, [server_id])
      {:ok, components} = CacheInternal.lookup({:server, :components}, [server_id])

      :ok = PurgeInternal.purge(:storage, storage_id)

      :miss = CacheInternal.direct_query(:server, server_id)
      :miss = CacheInternal.direct_query(:storage, storage_id)
      :miss = CacheInternal.direct_query(:component, List.first(components))
      :miss = CacheInternal.direct_query(:network, [nip.network_id, nip.ip])

      :timer.sleep(10)
    end

    test "purging component deletes everything", context do
      server_id = context.server.server_id
      motherboard_id = context.server.motherboard_id

      {:ok, [nip]} = CacheInternal.lookup({:server, :nips}, [server_id])
      {:ok, [storage_id]} = CacheInternal.lookup({:server, :storages}, [server_id])
      {:ok, components} = CacheInternal.lookup({:server, :components}, [server_id])

      PopulateInternal.populate(:component, motherboard_id)

      :ok = PurgeInternal.purge(:component, motherboard_id)

      :miss = CacheInternal.direct_query(:server, server_id)
      :miss = CacheInternal.direct_query(:storage, storage_id)
      :miss = CacheInternal.direct_query(:component, List.first(components))
      :miss = CacheInternal.direct_query(:network, [nip.network_id, nip.ip])

      :timer.sleep(10)
    end

    test "purging network deletes everything", context do
      server_id = context.server.server_id

      {:ok, [nip]} = CacheInternal.lookup({:server, :nips}, [server_id])
      {:ok, [storage_id]} = CacheInternal.lookup({:server, :storages}, [server_id])
      {:ok, components} = CacheInternal.lookup({:server, :components}, [server_id])

      :ok = PurgeInternal.purge(:network, nip.network_id, nip.ip)

      :miss = CacheInternal.direct_query(:server, server_id)
      :miss = CacheInternal.direct_query(:storage, storage_id)
      :miss = CacheInternal.direct_query(:component, List.first(components))
      :miss = CacheInternal.direct_query(:network, [nip.network_id, nip.ip])

      :timer.sleep(10)
    end
  end
end
