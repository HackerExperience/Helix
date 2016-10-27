defmodule HELM.Hardware.Controller.ComponentSpecTest do
  use ExUnit.Case

  alias HELL.Random, as: HRand
  alias HELM.Hardware.Controller.ComponentType, as: CtrlCompTypes
  alias HELM.Hardware.Controller.ComponentSpec, as: CtrlCompSpec

  setup do
    type_name = HRand.random_numeric_string()
    payload = %{component_type: type_name, spec: %{}}
    {:ok, type_name: type_name, payload: payload}
  end

  test "create/1", %{type_name: type_name, payload: payload} do
    {:ok, _} = CtrlCompTypes.create(type_name)
    assert {:ok, _} = CtrlCompSpec.create(payload)
  end

  describe "find/1" do
    test "success", %{type_name: type_name, payload: payload} do
      {:ok, _} = CtrlCompTypes.create(type_name)
      {:ok, comp_spec} = CtrlCompSpec.create(payload)
      assert {:ok, ^comp_spec} = CtrlCompSpec.find(comp_spec.spec_id)
    end

    test "failure" do
      assert {:error, :notfound} = CtrlCompSpec.find("")
    end
  end

  test "delete/1 idempotency", %{type_name: type_name, payload: payload} do
    {:ok, _} = CtrlCompTypes.create(type_name)
    {:ok, comp_spec} = CtrlCompSpec.create(payload)
    assert :ok = CtrlCompSpec.delete(comp_spec.spec_id)
    assert :ok = CtrlCompSpec.delete(comp_spec.spec_id)
  end
end