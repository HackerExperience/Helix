defmodule HELM.Server.Type.ControllerTest do
  use ExUnit.Case

  alias HELL.Random, as: HRand

  alias HELF.Broker
  alias HELM.Server.Type.Controller, as: ServerTypeCtrl
  alias HELM.Server.Controller, as: ServerCtrl
  alias HELM.Entity.Controller, as: EntityCtrl
  alias HELM.Entity.Server.Controller, as: EntityServerCtrl

  setup do
    {:ok, type: HRand.random_numeric_string()}
  end

  describe "create/1" do
    test "success", %{type: type} do
      assert {:ok, _} = ServerTypeCtrl.create(type)
    end
  end

  describe "find/1" do
    test "success", %{type: type} do
      {:ok, serv_type} = ServerTypeCtrl.create(type)
      assert {:ok, serv_type} = ServerTypeCtrl.find(serv_type.server_type)
    end
  end

  test "all/1 is always list" do
    assert is_list(ServerTypeCtrl.all())
  end

  test "delete/1 idempotency", %{type: type} do
    {:ok, serv_type} = ServerTypeCtrl.create(type)
    assert :ok = ServerTypeCtrl.delete(serv_type.server_type)
    assert :ok = ServerTypeCtrl.delete(serv_type.server_type)
  end
end
