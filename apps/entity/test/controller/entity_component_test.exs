defmodule Helix.Entity.Controller.EntityComponentTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Entity.Controller.Entity, as: EntityController
  alias Helix.Entity.Controller.EntityComponent, as: EntityComponentController
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Model.EntityType
  alias Helix.Entity.Repo

  setup_all do
    entity_type =
      EntityType
      |> Repo.all()
      |> Enum.random()

    {:ok, entity_type: entity_type.entity_type}
  end

  defp create_entity(entity_type) do
    params = %{
      entity_type: entity_type,
      reference_id: Random.pk()
    }

    entity =
      params
      |> Entity.create_changeset()
      |> Repo.insert!()

    entity.entity_id
  end

  defp create_components(entity_id) do
    components = Enum.map(0..Random.number(1..10), fn _ -> Random.pk() end)
    Enum.each(components, fn component_id ->
      {:ok, _} = EntityComponentController.create(entity_id, component_id)
    end)
    components
  end

  test "creating adds entity ownership over components", context do
    entity_id = create_entity(context.entity_type)
    components = create_components(entity_id)

    components1 = Enum.into(components, MapSet.new())
    components2 =
      entity_id
      |> EntityComponentController.find()
      |> Enum.map(&(&1.component_id))
      |> Enum.into(MapSet.new())

    # components are linked
    assert MapSet.equal?(components1, components2)
  end

  test "fetching yields an empty list when no component is owned", context do
    entity_id = create_entity(context.entity_type)
    assert [] == EntityComponentController.find(entity_id)
  end

  test "deleting the entity removes it's component ownership", context do
    entity_id = create_entity(context.entity_type)
    create_components(entity_id)

    # components are owned
    refute [] == EntityComponentController.find(entity_id)

    EntityController.delete(entity_id)

    # components aren't owned anymore
    assert [] == EntityComponentController.find(entity_id)
  end

  test "deleting is idempotent", context do
    entity_id = create_entity(context.entity_type)
    component_id = Random.pk()

    {:ok, _} = EntityComponentController.create(entity_id, component_id)
    :ok = EntityComponentController.delete(entity_id, component_id)
    :ok = EntityComponentController.delete(entity_id, component_id)

    assert [] == EntityComponentController.find(entity_id)
  end
end