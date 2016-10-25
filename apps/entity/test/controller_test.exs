defmodule HELM.Entity.ControllerTest do
  use ExUnit.Case

  alias HELL.Random, as: HRand
  alias HELM.Entity.Controller, as: EntityCtrl
  alias HELM.Entity.Type.Controller, as: EntityTypeCtrl

  setup do
    type = HRand.random_numeric_string()
    ref_id = HRand.random_numeric_string()
    payload = %{entity_type: type, reference_id: ref_id}
    {:ok, type: type, payload: payload}
  end

  test "create/1", %{type: type, payload: payload} do
    {:ok, enty_type} = EntityTypeCtrl.create(type)
    assert {:ok, _} = EntityCtrl.create(payload)
  end

  describe "find/1" do
    test "success", %{type: type, payload: payload} do
      {:ok, enty_type} = EntityTypeCtrl.create(type)
      {:ok, enty} = EntityCtrl.create(payload)
      assert {:ok, enty} = EntityCtrl.find(enty.entity_id)
    end

    test "failure" do
      assert {:error, :notfound} = EntityCtrl.find("")
    end
  end

  test "delete/1 idempotency", %{type: type, payload: payload} do
    {:ok, enty_type} = EntityTypeCtrl.create(type)
    {:ok, enty} = EntityCtrl.create(payload)
    assert :ok = EntityCtrl.delete(enty.entity_id)
    assert :ok = EntityCtrl.delete(enty.entity_id)
  end
end
