defmodule Helix.Cache.Integration.Hardware.ComponentTest do

  use Helix.Test.IntegrationCase

  import Helix.Test.CacheCase
  import Helix.Test.IDCase

  alias Helix.Hardware.Internal.Component, as: ComponentInternal
  alias Helix.Server.Internal.Server, as: ServerInternal
  alias Helix.Cache.Internal.Cache, as: CacheInternal
  alias Helix.Cache.Internal.Populate, as: PopulateInternal
  alias Helix.Cache.Helper, as: CacheHelper
  alias Helix.Cache.State.PurgeQueue, as: StatePurgeQueue

  setup do
    CacheHelper.cache_context()
  end

  describe "component integration" do
    test "component (mobo) deletion", context do
      server_id = context.server.server_id
      motherboard_id = context.server.motherboard_id

      PopulateInternal.populate(:by_server, server_id)

      motherboard_id
      |> ComponentInternal.fetch()
      |> ComponentInternal.delete()

      # Note: for completeness of context, we also need to detach the mobo from
      # the server, otherwise unexpected things happens. As always, you should
      # use the proper API.
      ServerInternal.detach(context.server)

      assert StatePurgeQueue.lookup(:component, motherboard_id)
      assert StatePurgeQueue.lookup(:server, server_id)

      StatePurgeQueue.sync()

      # We've deleted this server's mobo, so it won't have mobo's data on it
      assert {:hit, server} = CacheInternal.direct_query(:server, server_id)
      assert_id server.server_id, server_id
      assert server.entity_id
      refute server.motherboard_id

      # If you want to see the behavior of deleting a component other than
      # a motherboard, like cpu or ram, check the tests for motherboard unlink
      CacheHelper.sync_test()
    end

    test "component (mobo) deletion (cold)", context do
      server_id = context.server.server_id
      motherboard_id = context.server.motherboard_id

      motherboard_id
      |> ComponentInternal.fetch()
      |> ComponentInternal.delete()

      assert StatePurgeQueue.lookup(:component, motherboard_id)

      # No need to remove server since it doesn't exist on the cache anyways
      refute StatePurgeQueue.lookup(:server, server_id)

      StatePurgeQueue.sync()

      # We've deleted this server's mobo, so it will never populate correctly.
      assert_miss CacheInternal.direct_query(:server, server_id)

      CacheHelper.sync_test()
    end
  end
end
