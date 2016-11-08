defmodule HELM.Hardware.Controller.ComponentTest do
  use ExUnit.Case

  alias HELL.IPv6
  alias HELL.TestHelper.Random, as: HRand
  alias HELM.Hardware.Controller.ComponentType, as: CtrlCompType
  alias HELM.Hardware.Controller.ComponentSpec, as: CtrlCompSpec
  alias HELM.Hardware.Controller.Component, as: CtrlComps

  setup do
    type_name = HRand.string()
    spec_payload = %{component_type: type_name, spec: %{}}

    {:ok, comp_type} = CtrlCompType.create(type_name)
    {:ok, comp_spec} = CtrlCompSpec.create(spec_payload)

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
      assert {:error, :notfound} = CtrlComps.find(IPv6.generate([]))
    end
  end

  test "delete/1 idempotency", %{payload: payload} do
    assert {:ok, comp} = CtrlComps.create(payload)
    assert :ok = CtrlComps.delete(comp.component_id)
    assert :ok = CtrlComps.delete(comp.component_id)
  end
end