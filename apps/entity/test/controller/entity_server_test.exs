defmodule Helix.Entity.Controller.EntityServerTest do

  use ExUnit.Case, async: true

  alias Helix.Entity.Controller.EntityServer, as: EntityServerController

  alias Helix.Entity.Factory

  describe "adding entity ownership over servers" do
    test "succeeds with entity_id" do
      %{entity_id: entity_id} = Factory.insert(:entity)
      %{server_id: server_id} = Factory.build(:entity_server)

      assert {:ok, _} = EntityServerController.create(entity_id, server_id)
    end

    test "succeeds with entity struct" do
      entity = Factory.insert(:entity)
      %{server_id: server_id} = Factory.build(:entity_server)

      assert {:ok, _} = EntityServerController.create(entity, server_id)
    end

    test "fails when entity doesn't exist" do
      %{entity_id: entity_id} = Factory.build(:entity)
      %{server_id: server} = Factory.build(:entity_server)

      assert_raise(Ecto.ConstraintError, fn ->
        EntityServerController.create(entity_id, server)
      end)
    end
  end

  describe "fetching servers owned by an entity" do
    test "returns a list with owned servers" do
      entity = Factory.insert(:entity)
      servers = Factory.insert_list(5, :entity_server, %{entity: entity})
      expected_servers = Enum.map(servers, &(&1.server_id))
      fetched_servers = EntityServerController.find(entity)

      assert expected_servers == fetched_servers
    end

    test "returns an empty list when no server is owned" do
      entity = Factory.insert(:entity)
      fetched_servers = EntityServerController.find(entity)

      assert Enum.empty?(fetched_servers)
    end
  end

  test "removing entity ownership over servers is idempotent" do
    es = Factory.insert(:entity_server)

    refute Enum.empty?(EntityServerController.find(es.entity_id))

    EntityServerController.delete(es.entity_id, es.server_id)
    EntityServerController.delete(es.entity_id, es.server_id)

    assert Enum.empty?(EntityServerController.find(es.entity_id))
  end
end