defmodule HELM.Hardware.Controller.ComponentSpecsTest do
  use ExUnit.Case

  alias HELL.Random, as: HRand
  alias HELM.Hardware.Controller.ComponentTypes, as: CtrlCompTypes
  alias HELM.Hardware.Controller.ComponentSpecs, as: CtrlCompSpecs

  setup do
    type_name = HRand.random_numeric_string()
    payload = %{component_type: type_name, spec: %{}}
    {:ok, type_name: type_name, payload: payload}
  end

  test "create/1", %{type_name: type_name, payload: payload} do
    {:ok, _} = CtrlCompTypes.create(type_name)
    assert {:ok, _} = CtrlCompSpecs.create(payload)
  end

  describe "find/1" do
    test "success", %{type_name: type_name, payload: payload} do
      {:ok, _} = CtrlCompTypes.create(type_name)
      {:ok, comp_spec} = CtrlCompSpecs.create(payload)
      assert {:ok, ^comp_spec} = CtrlCompSpecs.find(comp_spec.spec_id)
    end

    test "failure" do
      assert {:error, :notfound} = CtrlCompSpecs.find("")
    end
  end

  test "delete/1 idempotency", %{type_name: type_name, payload: payload} do
    {:ok, _} = CtrlCompTypes.create(type_name)
    {:ok, comp_spec} = CtrlCompSpecs.create(payload)
    assert :ok = CtrlCompSpecs.delete(comp_spec.spec_id)
    assert :ok = CtrlCompSpecs.delete(comp_spec.spec_id)
  end
end