defmodule Helix.Entity.Internal.EntityTest do

  use Helix.Test.IntegrationCase

  alias Helix.Cache.Helper, as: CacheHelper
  alias Helix.Hardware.Model.Component
  alias Helix.Server.Model.Server
  alias Helix.Entity.Internal.Entity, as: EntityInternal
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Repo

  alias Helix.Entity.Factory

  defp generate_params do
    e = Factory.build(:entity)

    %{
      entity_id: e.entity_id,
      entity_type: e.entity_type
    }
  end

  describe "entity creation" do
    test "succeeds with valid params" do
      params = generate_params()
      {:ok, entity} = EntityInternal.create(params)

      assert entity.entity_id == params.entity_id
    end

    test "fails when entity_type is invalid" do
      {:error, cs} = EntityInternal.create(%{entity_type: :foobar})
      assert :entity_type in Keyword.keys(cs.errors)
    end
  end

  describe "fetch/1" do
    test "returns entity on success" do
      entity = Factory.insert(:entity)

      result = EntityInternal.fetch(entity.entity_id)

      assert result
      assert result.entity_id == entity.entity_id
    end

    test "returns nil if entity doesn't exists" do
      refute EntityInternal.fetch(Entity.ID.generate())
    end
  end

  describe "fetch_by_server/1" do
    test "returns entity if server is owned" do
      es = Factory.insert(:entity_server)

      result = EntityInternal.fetch_by_server(es.server_id)

      assert result
      assert result.entity_id == es.entity_id
    end

    test "returns nil if server is not owned" do
      refute EntityInternal.fetch_by_server(Server.ID.generate())
    end
  end

  describe "delete/1" do
    test "removes entry" do
      entity = Factory.insert(:entity)

      assert Repo.get(Entity, entity.entity_id)

      EntityInternal.delete(entity)

      refute Repo.get(Entity, entity.entity_id)
      CacheHelper.sync_test()
    end
  end

  describe "link_component/2" do
    test "succeeds with entity struct" do
      entity = Factory.insert(:entity)
      component_id = Component.ID.generate()

      {:ok, link} = EntityInternal.link_component(entity, component_id)

      assert link.component_id == component_id
      assert link.entity_id == entity.entity_id

      CacheHelper.sync_test()
    end

    test "fails when entity doesn't exist" do
      component_id = Component.ID.generate()
      {:error, _} = EntityInternal.link_component(%Entity{}, component_id)
    end
  end

  describe "unlink_component/2" do
    test "removing entity ownership over components is idempotent" do
      ec = Factory.insert(:entity_component)

      components =
        ec.entity
        |> Repo.preload(:components, force: true)
        |> Map.fetch!(:components)
      refute Enum.empty?(components)

      EntityInternal.unlink_component(ec.component_id)
      EntityInternal.unlink_component(ec.component_id)

      components =
        ec.entity
        |> Repo.preload(:components, force: true)
        |> Map.fetch!(:components)
      assert Enum.empty?(components)

      CacheHelper.sync_test()
    end
  end

  describe "link_server/2" do
    test "succeeds with entity struct" do
      entity = Factory.insert(:entity)
      server_id = Server.ID.generate()

      {:ok, link} = EntityInternal.link_server(entity, server_id)

      assert link.server_id == server_id
      assert link.entity_id == entity.entity_id

      CacheHelper.sync_test()
    end

    test "fails when entity doesn't exist" do
      server_id = Server.ID.generate()
      {:error, _} = EntityInternal.link_server(%Entity{}, server_id)
    end
  end

  describe "unlink_server/2" do
    test "removing entity ownership over servers is idempotent" do
      es = Factory.insert(:entity_server)

      servers =
        es.entity
        |> Repo.preload(:servers, force: true)
        |> Map.fetch!(:servers)
      refute Enum.empty?(servers)

      EntityInternal.unlink_server(es.server_id)
      EntityInternal.unlink_server(es.server_id)

      servers =
        es.entity
        |> Repo.preload(:servers, force: true)
        |> Map.fetch!(:servers)
      assert Enum.empty?(servers)

      CacheHelper.sync_test()
    end
  end
end
