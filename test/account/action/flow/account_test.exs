defmodule Helix.Account.Action.Flow.AccountTest do

  use Helix.Test.Case.Integration

  alias Helix.Test.Cache.Helper, as: CacheHelper
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Account.Action.Flow.Account, as: AccountFlow

  alias Helix.Test.Account.Setup, as: AccountSetup

  @relay nil

  describe "setup_account/1" do
    test "creates an entity" do
      {account, _} = AccountSetup.account()

      assert {:ok, %{entity: entity, server: server}} =
        AccountFlow.setup_account(account, @relay)

      CacheHelper.sync_test()

      # Generated entity has the correct id
      account_id = EntityQuery.get_entity_id(account)
      entity_id = EntityQuery.get_entity_id(entity)
      assert account_id == entity_id

      # Server is valid and registered to the entity
      assert [server_id] = EntityQuery.get_servers(entity)
      assert server_id == server.server_id
      assert server.motherboard_id

      # Components have been linked to the entity
      components = EntityQuery.get_components(entity)
      assert length(components) == 5
    end
  end
end
