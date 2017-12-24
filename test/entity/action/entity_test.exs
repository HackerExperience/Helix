defmodule Helix.Entity.Action.EntityTest do

  use Helix.Test.Case.Integration

  alias Helix.Entity.Action.Entity, as: EntityAction
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Query.Entity, as: EntityQuery

  alias Helix.Test.Account.Setup, as: AccountSetup

  describe "create_from_specialization/1" do
    test "derives an entity from an existing account" do
      account = AccountSetup.account!()

      assert {:ok, entity} = EntityAction.create_from_specialization(account)
      assert %Entity{} = entity

      assert EntityQuery.fetch(entity.entity_id)
    end
  end
end
