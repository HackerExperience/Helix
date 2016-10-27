defmodule HELM.Server.ControllerTest do
  use ExUnit.Case

  alias HELL.Random, as: HRand
  alias HELM.Server.Controller.ServerType, as: CtrlServerType
  alias HELM.Server.Controller.Server, as: CtrlServer

  setup do
    type = HRand.random_numeric_string()
    id = HRand.random_numeric_string()
    payload = %{server_type: type}
    {:ok, type: type, id: id, payload: payload}
  end

  test "create/2", %{type: type, payload: payload} do
    {:ok, _} = CtrlServerType.create(type)
    assert {:ok, _} = CtrlServer.create(payload)
  end

  describe "find/1" do
    test "success", %{type: type, payload: payload} do
      {:ok, _} = CtrlServerType.create(type)
      {:ok, serv} = CtrlServer.create(payload)
      assert {:ok, ^serv} = CtrlServer.find(serv.server_id)
    end

    test "failure" do
      assert {:error, :notfound} = CtrlServer.find("")
    end
  end

  test "delete/1 idempotency", %{type: type, payload: payload} do
    {:ok, _} = CtrlServerType.create(type)
    {:ok, serv} = CtrlServer.create(payload)
    assert :ok = CtrlServer.delete(serv.server_id)
    assert :ok = CtrlServer.delete(serv.server_id)
  end
end