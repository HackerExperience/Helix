defmodule Helix.Entity.Controller.EntityTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Entity.Controller.Entity, as: EntityController
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Model.EntityType
  alias Helix.Entity.Repo

  setup_all do
    types = Repo.all(EntityType)
    [entity_types: types]
  end

  setup context do
    type = Enum.random(context.entity_types)
    {:ok, entity} = create_entity(type)
    {:ok, entity: entity}
  end

  defp create_entity(params_or_schema) do
    params = %{entity_type: params_or_schema.entity_type}
    EntityController.create(params)
  end

  test "fails to create when entity_type is invalid" do
    entity_type = Burette.Color.name()

    refute Repo.get_by(Entity, entity_type: entity_type)

    assert_raise(FunctionClauseError, fn ->
      EntityController.create(%{entity_type: entity_type})
    end)

    refute Repo.get_by(Entity, entity_type: entity_type)
  end

  describe "find/1" do
    test "succeeds when entity exists", %{entity: entity} do
      assert {:ok, _} = EntityController.find(entity.entity_id)
    end

    test "fails when no entity exists" do
      assert {:error, :notfound} === EntityController.find(Random.pk())
    end
  end

  test "delete is idempotent", %{entity: entity} do
    assert Repo.get_by(Entity, entity_id: entity.entity_id)
    EntityController.delete(entity.entity_id)
    EntityController.delete(entity.entity_id)
    refute Repo.get_by(Entity, entity_id: entity.entity_id)
  end
end