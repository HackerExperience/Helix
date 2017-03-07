defmodule Helix.Entity.Controller.EntityTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Entity.Controller.Entity, as: EntityController
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
      assert {:ok, _} = EntityController.create(params)
    end

    test "fails when entity_type is invalid" do
      params = %{generate_params() | entity_type: Random.number()}

      assert {:error, cs} = EntityController.create(params)
      assert :entity_type in Keyword.keys(cs.errors)
    end
  end

  describe "entity fetching" do
    test "succeeds by id" do
      entity = Factory.insert(:entity)

      assert {:ok, found_entity} = EntityController.find(entity.entity_id)
      assert entity.entity_id == found_entity.entity_id
    end

    test "fails when entity doesn't exists" do
      assert {:error, :notfound} == EntityController.find(Random.pk())
    end
  end

  describe "entity deleting" do
    test "succeeds by struct and id" do
      entity1 = Factory.insert(:entity)
      entity2 = Factory.insert(:entity)

      assert :ok == EntityController.delete(entity1)
      assert :ok == EntityController.delete(entity2.entity_id)

      refute Repo.get_by(Entity, entity_id: entity1.entity_id)
      refute Repo.get_by(Entity, entity_id: entity2.entity_id)
    end

    test "is idempotent" do
      entity = Factory.insert(:entity)

      assert Repo.get_by(Entity, entity_id: entity.entity_id)

      EntityController.delete(entity.entity_id)
      EntityController.delete(entity.entity_id)

      refute Repo.get_by(Entity, entity_id: entity.entity_id)
    end
  end
end