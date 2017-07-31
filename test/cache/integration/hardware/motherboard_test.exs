defmodule Helix.Cache.Integration.Hardware.MotherboardTest do

  use Helix.Test.IntegrationCase

  alias Helix.Hardware.Internal.Motherboard, as: MotherboardInternal
  alias Helix.Cache.Helper, as: CacheHelper
  alias Helix.Cache.Internal.Populate, as: PopulateInternal
  alias Helix.Cache.State.PurgeQueue, as: StatePurgeQueue

  setup do
    CacheHelper.cache_context()
  end

  describe "motherboard integration" do
    test "motherboard deletion", context do
      server_id = context.server.server_id
      motherboard_id = context.server.motherboard_id

      PopulateInternal.populate(:by_server, server_id)

      MotherboardInternal.delete(motherboard_id)

      assert StatePurgeQueue.lookup(:component, motherboard_id)

      # Note that the purged motherboard will soon be re-added to the DB
      # because it is still linked to server, and calling `purge_motherboard`
      # will call `CacheAction.update_server`, which will re-fetch the mobo.

      CacheHelper.sync_test()
    end
  end
end
