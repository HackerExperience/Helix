defmodule Helix.Cache.Internal.PopulateTest do

  use Helix.Test.IntegrationCase

  alias Helix.Server.Action.Server, as: ServerAction
  alias Helix.Server.Internal.Server, as: ServerInternal
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

  def direct_cache_query(server_id) do
    ServerCache.Query.by_server(server_id)
    |> Repo.one
  end

  describe "populate/2" do
    test "server side-populates other caches", context do
      server_id = context.server.server_id
      motherboard_id = context.server.motherboard_id

      {:ok, [nip]} = CacheInternal.lookup({:server, :nips}, server_id)
      {:ok, [storage_id]} = CacheInternal.lookup({:server, :storages}, server_id)
      {:ok, components} = CacheInternal.lookup({:server, :components}, server_id)

      StatePurgeQueue.sync()

      {:hit, cnip} = CacheInternal.direct_query(:network, {nip.network_id, nip.ip})

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

      CacheHelper.sync_test()
    end

    test "populate server with nil values", context do
      server_id = context.server.server_id

      # I could simply generate the params and call the PopulateInternal
      # `cache/1` method directly.... but we can't test private functions,
      # which makes this test (and all others on this module) totally dependent
      # on external state, side-effects, etc. ¯\_(ツ)_/¯
      # Since we can't test at the Internal level (i.e. some integration is
      # required), you will find this same test at the cache integration tests

      ServerInternal.detach(context.server)

      StatePurgeQueue.sync()

      assert {:hit, server} = CacheInternal.direct_query(:server, server_id)

      assert server.server_id == server_id
      assert server.entity_id
      refute server.motherboard_id
      refute server.components
      refute server.storages
      refute server.networks
      refute server.resources

      CacheHelper.sync_test()
    end

    test "pre-existing cached entries are updated", context do
      server_id = context.server.server_id

      {:ok, server1} = PopulateInternal.populate(:by_server, server_id)

      ServerAction.detach(context.server)

      {:ok, server2} = PopulateInternal.populate(:by_server, server_id)

      refute server1 == server2
      assert server2.motherboard_id == nil

      CacheHelper.sync_test()
    end

    test "component population", context do
      motherboard_id = context.server.motherboard_id

      {:ok, component} = PopulateInternal.populate(:by_component, motherboard_id)

      {:hit, query} = CacheInternal.direct_query(:component, motherboard_id)

      assert component.component_id == query.component_id

      CacheHelper.sync_test()
    end

    test "storage population", context do
      {:ok, origin} = BuilderInternal.by_server(context.server.server_id)

      storage_id = List.first(origin.storages)

      {:ok, storage1} = PopulateInternal.populate(:by_storage, storage_id)

      {:hit, storage2} = CacheInternal.direct_query(:storage, storage_id)

      assert storage1.storage_id == storage2.storage_id

      CacheHelper.sync_test()
    end

    test "network population", context do
      {:ok, origin} = BuilderInternal.by_server(context.server.server_id)

      nip = List.first(origin.networks)

      {:ok, nip1} = PopulateInternal.populate(:by_nip, {nip.network_id, nip.ip})

      {:hit, nip2} = CacheInternal.direct_query(:network, {nip.network_id, nip.ip})

      assert nip1.network_id == nip2.network_id

      CacheHelper.sync_test()
    end
  end

  describe "minimal cache duration" do
    test "entries have a minimal cache duration", context do
      server_id = context.server.server_id

      {:ok, [nip]} = CacheInternal.lookup({:server, :nips}, server_id)
      {:ok, [storage_id]} = CacheInternal.lookup({:server, :storages}, server_id)
      {:ok, components} = CacheInternal.lookup({:server, :components}, server_id)

      StatePurgeQueue.sync()

      {:hit, cserver} = CacheInternal.direct_query(:server, server_id)
      {:hit, cnip} = CacheInternal.direct_query(:network, {nip.network_id, nip.ip})
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

      CacheHelper.sync_test()
    end
  end
end
