defmodule HELM.Hardware.Controller.ComponentTypesTest do
  use ExUnit.Case

  alias HELL.Random, as: HRand
  alias HELM.Hardware.Controller.ComponentTypes, as: CtrlCompTypes

  setup do
    {:ok, type_name: HRand.random_numeric_string()}
  end

  test "create/1", %{type_name: type_name} do
    assert {:ok, _} = CtrlCompTypes.create(type_name)
  end

  describe "find/1" do
    test "success", %{type_name: type_name} do
      {:ok, comp_type} = CtrlCompTypes.create(type_name)
      assert {:ok, ^comp_type} = CtrlCompTypes.find(comp_type.component_type)
    end

    test "failure" do
      assert {:error, :notfound} = CtrlCompTypes.find("")
    end
  end

  describe "all/0" do
    test "yields a list" do
      assert is_list CtrlCompTypes.all()
    end

    test "includes component", %{type_name: type_name} do
      {:ok, comp_type} = CtrlCompTypes.create(type_name)
      types = CtrlCompTypes.all()
      assert Enum.member?(types, comp_type.component_type)
    end
  end

  test "delete/1 idempotency", %{type_name: type_name} do
    {:ok, comp_type} = CtrlCompTypes.create(type_name)
    assert :ok = CtrlCompTypes.delete(comp_type.component_type)
    assert :ok = CtrlCompTypes.delete(comp_type.component_type)
  end
end