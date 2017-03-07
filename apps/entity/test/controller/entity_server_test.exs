defmodule Helix.Entity.Controller.EntityServerTest do

  use ExUnit.Case, async: true

  alias Helix.Entity.Controller.EntityServer, as: EntityServerController
  alias Helix.Entity.Model.EntityServer
  alias Helix.Entity.Repo

  alias Helix.Entity.Factory

  describe "adding entity ownership over servers" do
    test "succeeds with entity_id" do
      %{entity_id: entity_id} = Factory.insert(:entity)
      %{server_id: comp_id} = Factory.build(:entity_server)

      assert {:ok, _} = EntityServerController.create(entity_id, comp_id)
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
      servers = Factory.build_list(5, :entity_server, %{entity: entity})
      fetched_servers = EntityServerController.find(entity)

      assert [] == (fetched_servers -- servers)
    end

    test "returns an empty list when no server is owned" do
      entity = Factory.insert(:entity)
      fetched_servers = EntityServerController.find(entity)

      assert [] == fetched_servers
    end
  end

  test "removing entity ownership over servers is idempotent" do
    ec = Factory.insert(:entity_server)

    assert Repo.get_by(EntityServer, entity_id: ec.entity_id)

    EntityServerController.delete(ec.entity_id, ec.server_id)
    EntityServerController.delete(ec.entity_id, ec.server_id)

    refute Repo.get_by(EntityServer, entity_id: ec.entity_id)
  end
end