defmodule Helix.Entity.Service.API.EntityTest do

  use Helix.Test.IntegrationCase

  alias HELL.TestHelper.Random
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Repo
  alias Helix.Entity.Service.API.Entity, as: API

  alias Helix.Account.Factory, as: AccountFactory
  alias Helix.Entity.Factory

  describe "create_from_specialization/1" do
    test "derives an entity from an existing account" do
      account = AccountFactory.insert(:account)

      assert {:ok, entity = %Entity{}} = API.create_from_specialization(account)
      assert Repo.get(Entity, entity.entity_id)
    end
  end

  describe "get_servers_from_entity/1" do
    test "returns list of server ids owned by entity" do
      entity = Factory.insert(:entity)

      server_ids = Enum.map(1..5, fn _ ->
        server_id = Random.pk()

        API.link_server(entity, server_id)

        server_id
      end)

      server_ids = MapSet.new(server_ids)
      entity_servers = MapSet.new(API.get_servers_from_entity(entity))
      assert MapSet.equal?(server_ids, entity_servers)
    end
  end
end
