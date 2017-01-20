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

  defp create_entity(context) do
    params = %{
      entity_type: context.entity_type,
      reference_id: Random.pk()
    }

    entity =
      params
      |> Entity.create_changeset()
      |> Repo.insert!()

    entity.entity_id
  end

  defp create_components(entity_id, components) do
    Enum.each(components, fn component_id ->
      {:ok, _} = EntityComponentController.create(entity_id, component_id)
    end)
  end

  defp generate_components() do
    Enum.map(0..Random.number(1..10), fn _ -> Random.pk() end)
  end

  test "creating adds entity ownership over components", context do
    entity_id = create_entity(context)
    components = generate_components()
    create_components(entity_id, components)

    components1 = Enum.into(components, MapSet.new())
    components2 =
      entity_id
      |> EntityComponentController.find()
      |> Enum.map(&(&1.component_id))
      |> Enum.into(MapSet.new())

    # components are linked
    assert components1 == components2
  end

  test "fetching yields an empty list when no component is owned", context do
    entity_id = create_entity(context)
    assert [] == EntityComponentController.find(entity_id)
  end

  test "deleting the entity removes it's componente ownership", context do
    entity_id = create_entity(context)
    components = generate_components()
    create_components(entity_id, components)

    # components are owned
    refute [] == EntityComponentController.find(entity_id)

    EntityController.delete(entity_id)

    # components aren't owned anymore
    assert [] == EntityComponentController.find(entity_id)
  end

  test "deleting is idempotent", context do
    entity_id = create_entity(context)
    component_id = Random.pk()

    {:ok, _} = EntityComponentController.create(entity_id, component_id)
    :ok = EntityComponentController.delete(entity_id, component_id)
    :ok = EntityComponentController.delete(entity_id, component_id)

    assert [] == EntityComponentController.find(entity_id)
  end
end