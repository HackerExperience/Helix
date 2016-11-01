defmodule HELM.Server.Type.ControllerTest do
  use ExUnit.Case

  alias HELL.TestHelper.Random, as: HRand
  alias HELM.Server.Controller.ServerType, as: CtrlServerType

  setup do
    {:ok, type: HRand.string()}
  end

  describe "create/1" do
    test "success", %{type: type} do
      assert {:ok, _} = CtrlServerType.create(type)
    end
  end

  describe "find/1" do
    test "success", %{type: type} do
      {:ok, serv_type} = CtrlServerType.create(type)
      assert {:ok, serv_type} === CtrlServerType.find(serv_type.server_type)
    end

    test "failure" do
      assert {:error, :notfound} === CtrlServerType.find("")
    end
  end

  test "all/1 is always list" do
    assert is_list(CtrlServerType.all())
  end

  test "delete/1 idempotency", %{type: type} do
    {:ok, serv_type} = CtrlServerType.create(type)
    assert :ok === CtrlServerType.delete(serv_type.server_type)
    assert :ok === CtrlServerType.delete(serv_type.server_type)
  end
end