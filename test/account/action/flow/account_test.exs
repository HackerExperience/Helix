defmodule Helix.Account.Action.Flow.AccountTest do

  use Helix.Test.Case.Integration

  alias Helix.Test.Cache.Helper, as: CacheHelper
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Account.Action.Flow.Account, as: AccountFlow

  alias Helix.Test.Account.Factory

  describe "setup_account/1" do
    test "creates an entity" do
      account = Factory.insert(:account)

      result = AccountFlow.setup_account(account)
      CacheHelper.sync_test()

      assert {:ok, %{entity: entity}} = result
      assert %Entity{} = entity

      account_id = EntityQuery.get_entity_id(account)
      entity_id = EntityQuery.get_entity_id(entity)
      assert account_id == entity_id
    end
  end
end
