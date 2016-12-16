defmodule HELM.Entity.Controller.EntityTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias HELM.Entity.Repo
  alias HELM.Entity.Model.Entity
  alias HELM.Entity.Model.EntityType
  alias Helix.Entity.Model.EntityAccount
  alias Helix.Entity.Model.EntityNPC
  alias Helix.Entity.Model.EntityClan
  alias HELM.Entity.Controller.Entity, as: EntityController

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

  defp get_specialization(entity = %{entity_type: "account"}),
    do: get_specialization(EntityAccount, entity)
  defp get_specialization(entity = %{entity_type: "npc"}),
    do: get_specialization(EntityNPC, entity)
  defp get_specialization(entity = %{entity_type: "clan"}),
    do: get_specialization(EntityClan, entity)

  defp get_specialization(model, entity) do
    case Repo.get_by(model, entity_id: entity.entity_id) do
      nil ->
        {:error, :notfound}
      specialization ->
        {:ok, specialization}
    end
  end

  describe "create/1" do
    test "fails when entity_type is invalid" do
      entity_type = Burette.Color.name()

      refute Repo.get_by(Entity, entity_type: entity_type)

      assert_raise(FunctionClauseError, fn ->
        EntityController.create(%{entity_type: entity_type})
      end)

      refute Repo.get_by(Entity, entity_type: entity_type)
    end

    test "creates specializations for every valid entity_type", %{entity_types: entity_types} do
      Enum.each(entity_types, fn params ->
        {:ok, entity} = create_entity(params)
        {:ok, specialization} = get_specialization(entity)

        assert entity.entity_id == specialization.entity_id
      end)
    end
  end

  describe "find/1" do
    test "succeeds when entity exists", %{entity: entity} do
      assert {:ok, _} = EntityController.find(entity.entity_id)
    end

    test "fails when no entity exists" do
      assert {:error, :notfound} === EntityController.find(Random.pk())
    end
  end

  describe "delete/1" do
    test "delete is idempotent", %{entity: entity} do
      assert Repo.get_by(Entity, entity_id: entity.entity_id)
      EntityController.delete(entity.entity_id)
      EntityController.delete(entity.entity_id)
      refute Repo.get_by(Entity, entity_id: entity.entity_id)
    end

    test "deletes specialization for given entity", %{entity: entity} do
      {:ok, specialization} = get_specialization(entity)
      assert Repo.get_by(Entity, entity_id: entity.entity_id)
      EntityController.delete(entity.entity_id)
      assert {:error, :notfound} == get_specialization(entity)
    end
  end
end