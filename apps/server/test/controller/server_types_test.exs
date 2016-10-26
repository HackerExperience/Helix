defmodule HELM.Server.Type.ControllerTest do
  use ExUnit.Case

  alias HELL.Random, as: HRand

  alias HELF.Broker
  alias HELM.Server.Controller.ServerTypes, as: CtrlServerTypes

  setup do
    {:ok, type: HRand.random_numeric_string()}
  end

  describe "create/1" do
    test "success", %{type: type} do
      assert {:ok, _} = CtrlServerTypes.create(type)
    end
  end

  describe "find/1" do
    test "success", %{type: type} do
      {:ok, serv_type} = CtrlServerTypes.create(type)
      assert {:ok, serv_type} = CtrlServerTypes.find(serv_type.server_type)
    end

    test "failure", %{type: type} do
      assert {:error, :notfound} = CtrlServerTypes.find("")
    end
  end

  test "all/1 is always list" do
    assert is_list(CtrlServerTypes.all())
  end

  test "delete/1 idempotency", %{type: type} do
    {:ok, serv_type} = CtrlServerTypes.create(type)
    assert :ok = CtrlServerTypes.delete(serv_type.server_type)
    assert :ok = CtrlServerTypes.delete(serv_type.server_type)
  end
end