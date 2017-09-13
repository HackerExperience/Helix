defmodule Helix.Entity.Action.EntityTest do

  use Helix.Test.Case.Integration

  alias Helix.Entity.Action.Entity, as: EntityAction
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Repo

  alias Helix.Test.Account.Factory, as: AccountFactory

  describe "create_from_specialization/1" do
    test "derives an entity from an existing account" do
      account = AccountFactory.insert(:account)

      assert {:ok, entity} = EntityAction.create_from_specialization(account)
      assert %Entity{} = entity
      assert Repo.get(Entity, entity.entity_id)
    end
  end
end
