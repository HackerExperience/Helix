defmodule Helix.Cache.Integration.Server.ServerTest do

  use Helix.Test.IntegrationCase

  alias Helix.Server.Internal.Server, as: ServerInternal
  alias Helix.Cache.Helper, as: CacheHelper
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

      {:ok, components} =
        CacheQuery.from_motherboard_get_components(motherboard_id)
      StatePurgeQueue.sync()

      refute StatePurgeQueue.lookup(:server, server_id)
      refute StatePurgeQueue.lookup(:component, motherboard_id)

      assert {:ok, _} = ServerInternal.attach(context.server, motherboard_id)

      assert StatePurgeQueue.lookup(:server, server_id)
      assert StatePurgeQueue.lookup(:component, motherboard_id)
      Enum.map(components, fn(component_id) ->
        assert StatePurgeQueue.lookup(:component, component_id)
      end)

      StatePurgeQueue.sync()

      assert {:hit, server} = CacheInternal.direct_query(:server, server_id)

      assert server.server_id == server_id
      assert server.entity_id
      assert server.motherboard_id
      assert server.components
      assert server.storages
      assert server.networks
      assert server.resources

      refute StatePurgeQueue.lookup(:server, server_id)
      refute StatePurgeQueue.lookup(:component, motherboard_id)

      CacheHelper.sync_test()
    end

    test "detach motherboard cleans cache", context do
      server_id = context.server.server_id
      motherboard_id = context.server.motherboard_id

      {:ok, server} = PopulateInternal.populate(:by_server, server_id)
      components = server.components

      {:hit, _} = CacheInternal.direct_query(:server, server_id)

      refute StatePurgeQueue.lookup(:server, server_id)

      ServerInternal.detach(context.server)

      assert StatePurgeQueue.lookup(:server, server_id)
      assert StatePurgeQueue.lookup(:component, motherboard_id)
      assert StatePurgeQueue.lookup(:component, Enum.random(components))

      StatePurgeQueue.sync()

      assert {:hit, server} = CacheInternal.direct_query(:server, server_id)

      assert server.server_id == server_id
      assert server.entity_id
      refute server.motherboard_id
      refute server.components
      refute server.storages
      refute server.networks
      refute server.resources

      :miss = CacheInternal.direct_query(:component, motherboard_id)

      # Note that the mobo components still exist, because ideally one should
      # detach a motherboard only after all components have been removed.
      # Since we called ServerInternal directly, we've bypassed this rule.
      Enum.each(components, fn(component_id) ->
        assert {:hit, _} = CacheInternal.direct_query(:component, component_id)
      end)

      CacheHelper.sync_test()
    end

    test "detach motherboard cleans cache (cold)", context do
      server_id = context.server.server_id
      motherboard_id = context.server.motherboard_id

      {:ok, server} = BuilderInternal.by_server(server_id)
      components = server.components

      refute StatePurgeQueue.lookup(:server, server_id)

      ServerInternal.detach(context.server)

      assert StatePurgeQueue.lookup(:component, motherboard_id)
      refute StatePurgeQueue.lookup(:server, server_id)
      refute StatePurgeQueue.lookup(:component, Enum.random(components))

      CacheHelper.sync_test()
    end

    test "deleting server cleans cache", context do
      server_id = context.server.server_id
      motherboard_id = context.server.motherboard_id

      {:ok, server} = PopulateInternal.populate(:by_server, server_id)

      nip = Enum.random(server.networks)

      refute StatePurgeQueue.lookup(:server, server_id)

      ServerInternal.delete(server_id)

      assert StatePurgeQueue.lookup(:server, server_id)
      assert StatePurgeQueue.lookup(:component, motherboard_id)
      Enum.map(server.components, fn(component_id) ->
        assert StatePurgeQueue.lookup(:component, component_id)
      end)
      Enum.map(server.storages, fn(storage_id) ->
        assert StatePurgeQueue.lookup(:storage, storage_id)
      end)
      assert StatePurgeQueue.lookup(:network, {nip.network_id, nip.ip})

      StatePurgeQueue.sync()

      assert {:error, reason} = CacheQuery.from_server_get_all(server_id)
      assert reason == {:server, :notfound}

      CacheHelper.sync_test()
    end

    test "deleting server cleans cache (cold)", context do
      server_id = context.server.server_id
      motherboard_id = context.server.motherboard_id

      {:ok, server} = BuilderInternal.by_server(server_id)

      nip = Enum.random(server.networks)

      refute StatePurgeQueue.lookup(:server, server_id)

      ServerInternal.delete(server_id)

      assert StatePurgeQueue.lookup(:server, server_id)
      refute StatePurgeQueue.lookup(:component, motherboard_id)
      Enum.map(server.components, fn(component_id) ->
        refute StatePurgeQueue.lookup(:component, component_id)
      end)
      refute StatePurgeQueue.lookup(:component, Enum.random(server.components))
      Enum.map(server.storages, fn(storage_id) ->
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
