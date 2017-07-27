defmodule Helix.Cache.Internal.PopulateTest do

  use Helix.Test.IntegrationCase

  alias Helix.Hardware.Query.Motherboard, as: MotherboardQuery
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Server.Action.Server, as: ServerAction
  alias Helix.Cache.Internal.Cache, as: CacheInternal
  alias Helix.Cache.Internal.Populate, as: PopulateInternal
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

  describe "populate/2,3" do
    test "server side-populates other caches", context do
      server_id = context.server.server_id
      motherboard_id = context.server.motherboard_id

      {:ok, [nip]} = CacheInternal.lookup({:server, :nips}, [server_id])
      {:ok, [storage_id]} = CacheInternal.lookup({:server, :storages}, [server_id])
      {:ok, components} = CacheInternal.lookup({:server, :components}, [server_id])

      # Cache population is asynchronous..
      :timer.sleep(20)

      {:hit, cnip} = CacheInternal.direct_query(:network, [nip.network_id, nip.ip])

      refute cnip == nil
      assert cnip.server_id == server_id

      {:hit, cstorage} = CacheInternal.direct_query(:storage, storage_id)

      refute cstorage == nil
      assert cstorage.storage_id == storage_id

      {:hit, ccomponent} = CacheInternal.direct_query(:component, List.first(components))

      refute ccomponent == nil
      assert ccomponent.motherboard_id == motherboard_id

      # Regression: motherboard is also added to components
      {:hit, cmobo} = CacheInternal.direct_query(:component, motherboard_id)

      refute cmobo == nil
      assert cmobo.component_id == motherboard_id

      :timer.sleep(10)
    end

    test "pre-existing cached entries are updated", context do
      server_id = context.server.server_id

      {:ok, server1} = PopulateInternal.populate(:server, server_id)
      :timer.sleep(20)

      ServerAction.detach(context.server)

      {:ok, server2} = PopulateInternal.populate(:server, server_id)

      refute server1 == server2
      assert server2.motherboard_id == nil

      :timer.sleep(10)
    end

    test "component population", context do
      motherboard_id = context.server.motherboard_id

      {:ok, component} = PopulateInternal.populate(:component, motherboard_id)

      {:hit, query} = CacheInternal.direct_query(:component, motherboard_id)

      assert component.component_id == query.component_id

      :timer.sleep(10)
    end

    test "storage population", context do
      motherboard_id = context.server.motherboard_id

      [storage|_] = MotherboardQuery.get_storages(motherboard_id)

      {:ok, storage1} = PopulateInternal.populate(:storage, storage.storage_id)

      {:hit, storage2} = CacheInternal.direct_query(:storage, storage.storage_id)

      assert storage1.storage_id == storage2.storage_id

      :timer.sleep(10)
    end

    test "network population", context do
      server_id = context.server.server_id

      nip = ServerQuery.get_nips(server_id)
      |> List.first()

      {:ok, nip1} = PopulateInternal.populate(:network, nip.network_id, nip.ip)

      {:hit, nip2} = CacheInternal.direct_query(:network, [nip.network_id, nip.ip])

      assert nip1.network_id == nip2.network_id

      :timer.sleep(10)
    end
  end

  describe "minimal cache duration" do
    test "entries have a minimal cache duration", context do
      server_id = context.server.server_id

      {:ok, [nip]} = CacheInternal.lookup({:server, :nips}, [server_id])
      {:ok, [storage_id]} = CacheInternal.lookup({:server, :storages}, [server_id])
      {:ok, components} = CacheInternal.lookup({:server, :components}, [server_id])

      # Wait for it..
      :timer.sleep(50)

      {:hit, cserver} = CacheInternal.direct_query(:server, server_id)
      {:hit, cnip} = CacheInternal.direct_query(:network, [nip.network_id, nip.ip])
      {:hit, cstorage} = CacheInternal.direct_query(:storage, storage_id)
      {:hit, ccomponent} = CacheInternal.direct_query(:component, List.first(components))

      # Ensure cache has a minimal sane duration
      # Assertions may be changed if some entry do need to live for less
      # than 10 minutes, but that's a call to re-think whether you really
      # need such low-lived cache.
      assert DateTime.diff(cserver.expiration_date, DateTime.utc_now()) >= 600
      assert DateTime.diff(cnip.expiration_date, DateTime.utc_now()) >= 600
      assert DateTime.diff(cstorage.expiration_date, DateTime.utc_now()) >= 600
      assert DateTime.diff(ccomponent.expiration_date, DateTime.utc_now()) >= 600

      :timer.sleep(10)
    end
  end
end
