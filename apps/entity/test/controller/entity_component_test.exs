defmodule Helix.Entity.Controller.EntityComponentTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Entity.Controller.EntityComponent, as: EntityComponentController
  alias Helix.Entity.Model.EntityComponent
  alias Helix.Entity.Repo

  alias Helix.Entity.Factory

  def generate_all_owned_components(entity) do
    components = Enum.map(0..4, fn _ -> Random.pk() end)

    Enum.each(components, fn component ->
      EntityComponentController.create(entity, component)
    end)

    components
  end

  def reject_owned_components(owned, list) do
    owned_set = MapSet.new(owned)

    list
    |> MapSet.new()
    |> MapSet.difference(owned_set)
    |> MapSet.to_list()
  end

  describe "adding entity ownership over components" do
    test "succeeds with entity_id" do
      params = Factory.params(:entity_component)
      %{entity_id: pk, component_id: component} = params

      assert {:ok, _} = EntityComponentController.create(pk, component)
    end

    test "succeeds with entity struct" do
      params = Factory.params(:entity_component)
      %{entity: entity, component_id: component} = params

      assert {:ok, _} = EntityComponentController.create(entity, component)
    end

    test "fails when entity doesn't exist" do
      pk = Random.pk()
      %{component_id: component} = Factory.params(:entity_component)

      assert_raise(Ecto.ConstraintError, fn ->
        EntityComponentController.create(pk, component)
      end)
    end
  end

  describe "fetching components owned by an entity" do
    test "returns a list with owned components" do
      entity = Factory.insert(:entity)
      components = generate_all_owned_components(entity)
      fetched_components = EntityComponentController.find(entity)

      assert [] == reject_owned_components(components, fetched_components)
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