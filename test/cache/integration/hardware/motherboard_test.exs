defmodule Helix.Cache.Integration.Hardware.MotherboardTest do

  use Helix.Test.IntegrationCase

  alias Helix.Hardware.Internal.Motherboard, as: MotherboardInternal
  alias Helix.Cache.Action.Cache, as: CacheAction
  alias Helix.Cache.Internal.Cache, as: CacheInternal
  alias Helix.Cache.Internal.Populate, as: PopulateInternal
  alias Helix.Cache.State.PurgeQueue, as: StatePurgeQueue

  setup do
    alias Helix.Account.Factory, as: AccountFactory
    alias Helix.Account.Action.Flow.Account, as: AccountFlow

    account = AccountFactory.insert(:account)
    {:ok, %{server: server}} = AccountFlow.setup_account(account)

    {:ok, account: account, server: server}
  end

  describe "motherboard integration" do
    test "motherboard deletion", context do
      server_id = context.server.server_id
      motherboard_id = context.server.motherboard_id

      PopulateInternal.populate(:by_server, server_id)

      # Sync (wait for side-population)
      :timer.sleep(20)

      MotherboardInternal.delete(motherboard_id)

      assert StatePurgeQueue.lookup(:component, motherboard_id)

      # Note that the purged motherboard will soon be re-added to the DB
      # because it is still linked to server, and calling `purge_motherboard`
      # will call `CacheAction.update_server`, which will re-fetch the mobo.

      :timer.sleep(100)
    end
  end
end
