defmodule Helix.Entity.Controller.EntityServerTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Helpers
  alias HELL.TestHelper.Random
  alias Helix.Entity.Controller.EntityServer, as: EntityServerController
  alias Helix.Entity.Model.EntityServer
  alias Helix.Entity.Repo

  alias Helix.Entity.Factory

  describe "adding entity ownership over servers" do
    test "succeeds with entity_id" do
      params = Factory.params(:entity_server)
      %{entity_id: pk, server_id: server} = params

      assert {:ok, _} = EntityServerController.create(pk, server)
    end

    test "succeeds with entity struct" do
      params = Factory.params(:entity_server)
      %{entity: entity, server_id: server} = params

      assert {:ok, _} = EntityServerController.create(entity, server)
    end

    test "fails when entity doesn't exist" do
      pk = Random.pk()
      %{server_id: server} = Factory.params(:entity_server)

      assert_raise(Ecto.ConstraintError, fn ->
        EntityServerController.create(pk, server)
      end)
    end
  end

  describe "fetching servers owned by an entity" do
    test "returns a list with owned servers" do
      entity = Factory.insert(:entity)
      servers = Factory.servers_for(entity)
      fetched_servers = EntityServerController.find(entity)

      assert [] == Helpers.list_diff(servers, fetched_servers)
    end

    test "returns an empty list when no server is owned" do
      entity = Factory.insert(:entity)
      fetched_servers = EntityServerController.find(entity)

      assert [] == fetched_servers
    end
  end

  test "removing entity ownership over servers is idempotent" do
    es = Factory.insert(:entity_server)

    assert Repo.get_by(EntityServer, entity_id: es.entity_id)

    EntityServerController.delete(es.entity_id, es.server_id)
    EntityServerController.delete(es.entity_id, es.server_id)

    refute Repo.get_by(EntityServer, entity_id: es.entity_id)
  end
end