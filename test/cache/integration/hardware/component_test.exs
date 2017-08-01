defmodule Helix.Cache.Integration.Hardware.ComponentTest do

  use Helix.Test.IntegrationCase

  alias Helix.Hardware.Internal.Component, as: ComponentInternal
  alias Helix.Cache.Internal.Cache, as: CacheInternal
  alias Helix.Cache.Helper, as: CacheHelper
  alias Helix.Cache.State.PurgeQueue, as: StatePurgeQueue

  setup do
    CacheHelper.cache_context()
  end

  describe "component integration" do
    test "component deletion", context do
      server_id = context.server.server_id
      motherboard_id = context.server.motherboard_id

      ComponentInternal.delete(motherboard_id)

      assert StatePurgeQueue.lookup(:component, motherboard_id)

      StatePurgeQueue.sync()

      # We've deleted this server's mobo, so it will never populate correctly.
      :miss = CacheInternal.direct_query(:server, server_id)

      CacheHelper.sync_test()
    end
  end
end
