defmodule HELM.Server.ControllerTest do
  use ExUnit.Case

  alias HELL.Random, as: HRand
  alias HELF.Broker
  alias HELM.Server.Type.Controller, as: ServerTypeCtrl
  alias HELM.Server.Controller, as: ServerCtrl
  alias HELM.Entity.Controller, as: EntityCtrl
  alias HELM.Entity.Server.Controller, as: EntityServerCtrl

  setup do
    type = HRand.random_numeric_string()
    id = HRand.random_numeric_string()
    payload = %{server_type: type}
    {:ok, type: type, id: id, payload: payload}
  end

  test "create/2", %{type: type, payload: payload} do
    {:ok, serv_type} = ServerTypeCtrl.create(type)
    assert {:ok, _} = ServerCtrl.create(payload)
  end

  describe "find/1" do
    test "success", %{type: type, payload: payload} do
      {:ok, serv_type} = ServerTypeCtrl.create(type)
      {:ok, serv} = ServerCtrl.create(payload)
      assert {:ok, serv} = ServerCtrl.find(serv.server_id)
    end

    test "failure", %{type: type, payload: payload} do
      assert {:error, :notfound} = ServerCtrl.find("")
    end
  end

  test "delete/1 idempotency", %{type: type, payload: payload} do
    {:ok, serv_type} = ServerTypeCtrl.create(type)
    {:ok, serv} = ServerCtrl.create(payload)
    assert :ok = ServerCtrl.delete(serv.server_id)
    assert :ok = ServerCtrl.delete(serv.server_id)
  end
end