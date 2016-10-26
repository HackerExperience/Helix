defmodule HELM.Entity.Controller.EntityServersTest do
  use ExUnit.Case

  alias HELL.Random, as: HRand
  alias HELM.Entity.Controller.Entities, as: CtrlEntities
  alias HELM.Entity.Controller.EntityTypes, as: CtrlEntityTypes
  alias HELM.Entity.Controller.EntityServers, as: CtrlEntityServers

  setup do
    type = HRand.random_numeric_string()
    ref_id = HRand.random_numeric_string()
    id = HRand.random_numeric_string()
    payload = %{entity_type: type, reference_id: ref_id}
    {:ok, type: type, id: id, payload: payload}
  end

  test "create/1", %{type: type, payload: payload, id: id} do
    {:ok, enty_type} = CtrlEntityTypes.create(type)
    {:ok, entity} = CtrlEntities.create(payload)
    assert {:ok, _} = CtrlEntityServers.create(id, entity.entity_id)
  end

  describe "find/1" do
    test "success", %{type: type, payload: payload, id: id} do
      {:ok, enty_type} = CtrlEntityTypes.create(type)
      {:ok, entity} = CtrlEntities.create(payload)
      {:ok, entity_server} = CtrlEntityServers.create(id, entity.entity_id)
      assert {:ok, entity_server} = CtrlEntityServers.find(entity_server.server_id)
    end

    test "failure", data do
      assert {:error, :notfound} = CtrlEntityServers.find("")
    end
  end

  test "delete/1 idempotency", %{type: type, payload: payload, id: id} do
    {:ok, enty_type} = CtrlEntityTypes.create(type)
    {:ok, entity} = CtrlEntities.create(payload)
    {:ok, entity_server} = CtrlEntityServers.create(id, entity.entity_id)
    assert :ok = CtrlEntityServers.delete(entity_server.server_id)
    assert :ok = CtrlEntityServers.delete(entity_server.server_id)
  end
end