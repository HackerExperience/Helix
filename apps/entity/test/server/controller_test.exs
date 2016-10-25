defmodule HELM.Entity.Server.ControllerTest do
  use ExUnit.Case

  alias HELL.Random, as: HRand
  alias HELM.Entity.Controller, as: EntityCtrl
  alias HELM.Entity.Type.Controller, as: EntityTypeCtrl
  alias HELM.Entity.Server.Controller, as: EntityServerCtrl

  setup do
    type = HRand.random_numeric_string()
    ref_id = HRand.random_numeric_string()
    id = HRand.random_numeric_string()
    payload = %{entity_type: type, reference_id: ref_id}
    {:ok, type: type, id: id, payload: payload}
  end

  test "create/1", %{type: type, payload: payload, id: id} do
    {:ok, enty_type} = EntityTypeCtrl.create(type)
    {:ok, entity} = EntityCtrl.create(payload)
    assert {:ok, _} = EntityServerCtrl.create(id, entity.entity_id)
  end

  describe "find/1" do
    test "success", %{type: type, payload: payload, id: id} do
      {:ok, enty_type} = EntityTypeCtrl.create(type)
      {:ok, entity} = EntityCtrl.create(payload)
      {:ok, entity_server} = EntityServerCtrl.create(id, entity.entity_id)
      assert {:ok, entity_server} = EntityServerCtrl.find(entity_server.server_id)
    end

    test "failure", data do
      assert {:error, :notfound} = EntityServerCtrl.find("")
    end
  end

  test "delete/1 idempotency", %{type: type, payload: payload, id: id} do
    {:ok, enty_type} = EntityTypeCtrl.create(type)
    {:ok, entity} = EntityCtrl.create(payload)
    {:ok, entity_server} = EntityServerCtrl.create(id, entity.entity_id)
    assert :ok = EntityServerCtrl.delete(entity_server.server_id)
    assert :ok = EntityServerCtrl.delete(entity_server.server_id)
  end
end
