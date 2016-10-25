defmodule HELM.Hardware.Controller.ComponentsTest do
  use ExUnit.Case

  alias HELL.Random, as: HRand
  alias HELM.Hardware.Controller.ComponentTypes, as: CtrlCompTypes
  alias HELM.Hardware.Controller.ComponentSpecs, as: CtrlCompSpecs
  alias HELM.Hardware.Controller.Components, as: CtrlComps

  setup do
    type_name = HRand.random_numeric_string()
    spec_payload = %{component_type: type_name, spec: %{}}

    {:ok, comp_type} = CtrlCompTypes.create(type_name)
    {:ok, comp_spec} = CtrlCompSpecs.create(spec_payload)

    payload = %{
      component_type: comp_type.component_type,
      spec_id: comp_spec.spec_id
    }

    {:ok, payload: payload}
  end

  test "create/1", %{payload: payload} do
    assert {:ok, _} = CtrlComps.create(payload)
  end

  describe "find/1" do
    test "success", %{payload: payload} do
      assert {:ok, comp} = CtrlComps.create(payload)
      assert {:ok, ^comp} = CtrlComps.find(comp.component_id)
    end

    test "failure" do
      assert {:error, :notfound} = CtrlComps.find("")
    end
  end

  test "delete/1 idempotency", %{payload: payload} do
    assert {:ok, comp} = CtrlComps.create(payload)
    assert :ok = CtrlComps.delete(comp.component_id)
    assert :ok = CtrlComps.delete(comp.component_id)
  end
end