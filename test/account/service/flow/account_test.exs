defmodule Helix.Account.Service.Flow.AccountTest do

  use Helix.Test.IntegrationCase

  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Service.API.Entity, as: EntityAPI
  alias Helix.Account.Service.Flow.Account, as: Flow

  alias Helix.Account.Factory

  describe "setup_account/1" do
    test "creates an entity" do
      account = Factory.insert(:account)

      result = Flow.setup_account(account)
      # FIXME: This is to ensure that all callbacks in the flow are executed
      #   before the test ends (otherwise the callbacks will not have access to
      #   the repo because Ecto.Sandbox)
      :timer.sleep(300)

      assert {:ok, %{entity: entity}} = result
      assert %Entity{} = entity

      account_id = EntityAPI.get_entity_id(account)
      entity_id = EntityAPI.get_entity_id(entity)
      assert account_id == entity_id
    end
  end
end
