defmodule HELM.Server.ControllerTest do
  use ExUnit.Case

  alias HELL.Random, as: HRand
  alias HELF.Broker
  alias HELM.Server.Controller.ServerTypes, as: CtrlServerTypes
  alias HELM.Server.Controller.Servers, as: CtrlServers

  setup do
    type = HRand.random_numeric_string()
    id = HRand.random_numeric_string()
    payload = %{server_type: type}
    {:ok, type: type, id: id, payload: payload}
  end

  test "create/2", %{type: type, payload: payload} do
    {:ok, serv_type} = CtrlServerTypes.create(type)
    assert {:ok, _} = CtrlServers.create(payload)
  end

  describe "find/1" do
    test "success", %{type: type, payload: payload} do
      {:ok, serv_type} = CtrlServerTypes.create(type)
      {:ok, serv} = CtrlServers.create(payload)
      assert {:ok, serv} = CtrlServers.find(serv.server_id)
    end

    test "failure", %{type: type, payload: payload} do
      assert {:error, :notfound} = CtrlServers.find("")
    end
  end

  test "delete/1 idempotency", %{type: type, payload: payload} do
    {:ok, serv_type} = CtrlServerTypes.create(type)
    {:ok, serv} = CtrlServers.create(payload)
    assert :ok = CtrlServers.delete(serv.server_id)
    assert :ok = CtrlServers.delete(serv.server_id)
  end
end