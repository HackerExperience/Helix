defmodule Helix.Cache.Integration.Entity.EntityTest do

  use Helix.Test.IntegrationCase

  alias Helix.Entity.Internal.Entity, as: EntityInternal
  alias Helix.Cache.Internal.Builder, as: BuilderInternal
  alias Helix.Cache.Internal.Cache, as: CacheInternal
  alias Helix.Cache.Internal.Populate, as: PopulateInternal
  alias Helix.Cache.Helper, as: CacheHelper
  alias Helix.Cache.State.PurgeQueue, as: StatePurgeQueue

  setup do
    CacheHelper.cache_context()
  end

  describe "entity integration" do
    test "entity deletion", context do
      server_id = context.server.server_id

      {:ok, server} = PopulateInternal.populate(:by_server, server_id)

      # Must unlink server first
      EntityInternal.unlink_server(server_id)
      EntityInternal.delete(server.entity_id)

      assert StatePurgeQueue.lookup(:server, server_id)
      assert StatePurgeQueue.lookup(:component, server.motherboard_id)
      assert StatePurgeQueue.lookup(:storage, Enum.random(server.storages))

      StatePurgeQueue.sync()

      assert :miss == CacheInternal.direct_query(:server, server_id)

      CacheHelper.sync_test()
    end

    test "entity deletion (cold)", context do
      server_id = context.server.server_id

      {:ok, server} = BuilderInternal.by_server(server_id)

      # Must unlink server first
      EntityInternal.unlink_server(server_id)
      EntityInternal.delete(server.entity_id)

      assert StatePurgeQueue.lookup(:server, server_id)
      refute StatePurgeQueue.lookup(:component, server.motherboard_id)
      refute StatePurgeQueue.lookup(:storage, Enum.random(server.storages))

      StatePurgeQueue.sync()

      assert :miss == CacheInternal.direct_query(:server, server_id)

      CacheHelper.sync_test()
    end

    test "unlink server from entity", context do
      server_id = context.server.server_id
      motherboard_id = context.server.motherboard_id

      {:ok, server} = PopulateInternal.populate(:by_server, server_id)

      nip = Enum.random(server.networks)

      EntityInternal.unlink_server(server_id)

      assert StatePurgeQueue.lookup(:server, server_id)
      assert StatePurgeQueue.lookup(:component, motherboard_id)
      assert StatePurgeQueue.lookup(:component, Enum.random(server.components))
      assert StatePurgeQueue.lookup(:storage, Enum.random(server.storages))
      assert StatePurgeQueue.lookup(:network, {nip.network_id, nip.ip})

      StatePurgeQueue.sync()

      assert :miss == CacheInternal.direct_query(:server, server_id)

      CacheHelper.sync_test()
    end

    test "unlink server from entity (cold)", context do
      server_id = context.server.server_id
      motherboard_id = context.server.motherboard_id

      EntityInternal.unlink_server(server_id)

      assert StatePurgeQueue.lookup(:server, server_id)
      refute StatePurgeQueue.lookup(:component, motherboard_id)

      StatePurgeQueue.sync()

      assert :miss == CacheInternal.direct_query(:server, server_id)
    end
  end
end
