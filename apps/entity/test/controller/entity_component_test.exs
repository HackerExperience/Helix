defmodule Helix.Entity.Controller.EntityComponentTest do

  use ExUnit.Case, async: true

  alias Helix.Entity.Controller.EntityComponent, as: EntityComponentController
  alias Helix.Entity.Model.EntityComponent
  alias Helix.Entity.Repo

  alias Helix.Entity.Factory

  describe "adding entity ownership over components" do
    test "succeeds with entity_id" do
      %{entity_id: entity_id} = Factory.insert(:entity)
      %{component_id: comp_id} = Factory.build(:entity_component)

      assert {:ok, _} = EntityComponentController.create(entity_id, comp_id)
    end

    test "succeeds with entity struct" do
      entity = Factory.insert(:entity)
      %{component_id: component_id} = Factory.build(:entity_component)

      assert {:ok, _} = EntityComponentController.create(entity, component_id)
    end

    test "fails when entity doesn't exist" do
      %{entity_id: entity_id} = Factory.build(:entity)
      %{component_id: component} = Factory.build(:entity_component)

      assert_raise(Ecto.ConstraintError, fn ->
        EntityComponentController.create(entity_id, component)
      end)
    end
  end

  describe "fetching components owned by an entity" do
    test "returns a list with owned components" do
      entity = Factory.insert(:entity)
      components = Factory.build_list(5, :entity_component, %{entity: entity})
      fetched_components = EntityComponentController.find(entity)

      assert [] == (fetched_components -- components)
    end

    test "returns an empty list when no component is owned" do
      entity = Factory.insert(:entity)
      fetched_components = EntityComponentController.find(entity)

      assert [] == fetched_components
    end
  end

  test "removing entity ownership over components is idempotent" do
    ec = Factory.insert(:entity_component)

    assert Repo.get_by(EntityComponent, entity_id: ec.entity_id)

    EntityComponentController.delete(ec.entity_id, ec.component_id)
    EntityComponentController.delete(ec.entity_id, ec.component_id)

    refute Repo.get_by(EntityComponent, entity_id: ec.entity_id)
  end
end