defmodule Helix.Entity.Controller.EntityTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Entity.Controller.Entity, as: EntityController
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Model.EntityType
  alias Helix.Entity.Repo

  setup_all do
    entity_types = Repo.all(EntityType)
    [entity_types: entity_types]
  end

  setup context do
    entity_type = Enum.random(context.entity_types)
    {:ok, entity_type: entity_type.entity_type}
  end

  defp generate_params(entity_type) do
    %{
      entity_id: Random.pk(),
      entity_type: entity_type
    }
  end

  describe "entity creation" do
    test "creates entity of given type", context do
      params = generate_params(context.entity_type)
      {:ok, entity} = EntityController.create(params)
      {:ok, found_entity} = EntityController.find(params.entity_id)

      # created entity includes given id
      assert params.entity_id == entity.entity_id

      # find yields the same previously created entity
      assert entity.entity_id == found_entity.entity_id
    end

    test "fails when entity_type is invalid" do
      params = %{
        entity_id: Random.pk(),
        entity_type: Burette.Color.name()
      }

      # assert that creating an entity with invalid type raises Ecto.ConstraintError
      assert_raise(Ecto.ConstraintError, fn ->
        EntityController.create(params)
      end)

      # no entity was created
      refute Repo.get_by(Entity, entity_type: params.entity_type)
    end
  end

  describe "entity fetching" do
    test "fetches existing entity", context do
      params = generate_params(context.entity_type)
      {:ok, entity} = EntityController.create(params)

      # an entity is found
      assert {:ok, found_entity} = EntityController.find(entity.entity_id)

      # the entity is identical to the created one
      assert entity.entity_id == found_entity.entity_id
    end

    test "fails when entity doesn't exists" do
      assert {:error, :notfound} == EntityController.find(Random.pk())
    end
  end

  test "delete is idempotent", context do
    params = generate_params(context.entity_type)
    {:ok, entity} = EntityController.create(params)

    # entity exists before deleting
    assert Repo.get_by(Entity, entity_id: entity.entity_id)

    :ok = EntityController.delete(entity.entity_id)
    :ok = EntityController.delete(entity.entity_id)

    # entity was deleted
    refute Repo.get_by(Entity, entity_id: entity.entity_id)
  end
end