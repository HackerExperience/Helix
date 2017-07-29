defmodule Helix.Cache.Integration.Server.ServerTest do

  use Helix.Test.IntegrationCase

  alias Helix.Server.Internal.Server, as: ServerInternal
  alias Helix.Cache.Action.Cache, as: CacheAction
  alias Helix.Cache.Internal.Cache, as: CacheInternal
  alias Helix.Cache.Internal.Populate, as: PopulateInternal
  alias Helix.Cache.Query.Cache, as: CacheQuery

  setup do
    alias Helix.Account.Factory, as: AccountFactory
    alias Helix.Account.Action.Flow.Account, as: AccountFlow

    account = AccountFactory.insert(:account)
    {:ok, %{server: server}} = AccountFlow.setup_account(account)

    {:ok, account: account, server: server}
  end

  describe "server integration" do
    test "detach motherboard cleans cache", context do
      server_id = context.server.server_id
      motherboard_id = context.server.motherboard_id

      {:ok, components} =
        CacheQuery.from_motherboard_get_components(motherboard_id)
      :timer.sleep(20)

      ServerInternal.detach(context.server)
      :timer.sleep(20)

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

      :timer.sleep(100)
    end
  end
end
