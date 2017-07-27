defmodule Helix.Entity.Internal.EntityTest do

  use Helix.Test.IntegrationCase

  alias HELL.TestHelper.Random
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
      refute EntityInternal.fetch(Random.pk())
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
      refute EntityInternal.fetch_by_server(Random.pk())
    end
  end

  describe "entity deleting" do
    test "succeeds by struct" do
      entity = Factory.insert(:entity)

      assert Repo.get(Entity, entity.entity_id)
      EntityInternal.delete(entity)
      refute Repo.get(Entity, entity.entity_id)
    end

    test "succeeds by id" do
      entity = Factory.insert(:entity)

      assert Repo.get(Entity, entity.entity_id)
      EntityInternal.delete(entity.entity_id)
      refute Repo.get(Entity, entity.entity_id)
    end

    test "is idempotent" do
      entity = Factory.insert(:entity)

      assert Repo.get(Entity, entity.entity_id)

      EntityInternal.delete(entity.entity_id)
      EntityInternal.delete(entity.entity_id)

      refute Repo.get(Entity, entity.entity_id)
    end
  end

  describe "link_component/2" do
    test "succeeds with entity struct" do
      entity = Factory.insert(:entity)
      component_id = Random.pk()

      {:ok, link} = EntityInternal.link_component(entity, component_id)

      assert link.component_id == component_id
      assert link.entity_id == entity.entity_id
    end

    test "fails when entity doesn't exist" do
      {:error, _} = EntityInternal.link_component(%Entity{}, Random.pk())
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
    end
  end

  describe "link_server/2" do
    test "succeeds with entity struct" do
      entity = Factory.insert(:entity)
      server_id = Random.pk()

      {:ok, link} = EntityInternal.link_server(entity, server_id)

      assert link.server_id == server_id
      assert link.entity_id == entity.entity_id
    end

    test "fails when entity doesn't exist" do
      {:error, _} = EntityInternal.link_server(%Entity{}, Random.pk())
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
    end
  end
end
