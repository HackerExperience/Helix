defmodule HELM.Entity.Controller.EntitiesTest do
  use ExUnit.Case

  alias HELL.Random, as: HRand
  alias HELM.Entity.Controller.Entities, as: CtrlEntities
  alias HELM.Entity.Controller.EntityTypes, as: CtrlEntityTypes

  setup do
    type = HRand.random_numeric_string()
    ref_id = HRand.random_numeric_string()
    payload = %{entity_type: type, reference_id: ref_id}
    {:ok, type: type, payload: payload}
  end

  test "create/1", %{type: type, payload: payload} do
    {:ok, enty_type} = CtrlEntityTypes.create(type)
    assert {:ok, _} = CtrlEntities.create(payload)
  end

  describe "find/1" do
    test "success", %{type: type, payload: payload} do
      {:ok, enty_type} = CtrlEntityTypes.create(type)
      {:ok, enty} = CtrlEntities.create(payload)
      assert {:ok, enty} = CtrlEntities.find(enty.entity_id)
    end

    test "failure" do
      assert {:error, :notfound} = CtrlEntities.find("")
    end
  end

  test "delete/1 idempotency", %{type: type, payload: payload} do
    {:ok, enty_type} = CtrlEntityTypes.create(type)
    {:ok, enty} = CtrlEntities.create(payload)
    assert :ok = CtrlEntities.delete(enty.entity_id)
    assert :ok = CtrlEntities.delete(enty.entity_id)
  end
end