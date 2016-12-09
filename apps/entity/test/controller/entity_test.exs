defmodule HELM.Entity.Controller.EntityTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias HELM.Entity.Repo
  alias HELM.Entity.Model.Entity
  alias HELM.Entity.Model.EntityType
  alias HELM.Entity.Controller.Entity, as: CtrlEntity

  setup_all do
    # FIXME
    type = case Repo.all(EntityType) do
      [] ->
        %{entity_type: Burette.Color.name()}
        |> EntityType.create_changeset()
        |> Repo.insert!()
      et = [_|_] ->
        Enum.random(et)
    end

    [entity_type: type]
  end

  setup context do
    entity =
      %{
        entity_type: context.entity_type.entity_type,
        reference_id: Random.pk()}
      |> Entity.create_changeset()
      |> Repo.insert!()

    {:ok, entity: entity}
  end

  describe "find/1" do
    test "succeeds when entity exists", %{entity: entity} do
      assert {:ok, _} = CtrlEntity.find(entity.entity_id)
    end

    test "fails when no entity exists" do
      assert {:error, :notfound} === CtrlEntity.find(Random.pk())
    end
  end

  test "delete is idempotent", %{entity: entity} do
    assert Repo.get_by(Entity, entity_id: entity.entity_id)
    CtrlEntity.delete(entity.entity_id)
    CtrlEntity.delete(entity.entity_id)
    refute Repo.get_by(Entity, entity_id: entity.entity_id)
  end
end