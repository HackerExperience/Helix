defmodule HELM.Hardware.Controller.MotherboardSlotsTest do
  use ExUnit.Case

  alias HELL.Random, as: HRand
  alias HELM.Hardware.Controller.ComponentTypes, as: CtrlCompTypes
  alias HELM.Hardware.Controller.ComponentSpecs, as: CtrlCompSpecs
  alias HELM.Hardware.Controller.Components, as: CtrlComps
  alias HELM.Hardware.Controller.Motherboards, as: CtrlMobos
  alias HELM.Hardware.Controller.MotherboardSlots, as: CtrlMoboSlots

  setup do
    type_name = HRand.random_numeric_string()
    spec_payload = %{component_type: type_name, spec: %{}}

    {:ok, comp_type} = CtrlCompTypes.create(type_name)
    {:ok, comp_spec} = CtrlCompSpecs.create(spec_payload)

    comp_payload = %{component_type: comp_type.component_type, spec_id: comp_spec.spec_id}

    {:ok, comp} = CtrlComps.create(comp_payload)
    {:ok, mobo} = CtrlMobos.create()

    payload = %{
      slot_internal_id: HRand.random_number(),
      motherboard_id: mobo.motherboard_id,
      link_component_type: comp_type.component_type,
      link_component_id: comp.component_id
    }

    clean_payload = %{
      slot_internal_id: HRand.random_number(),
      motherboard_id: mobo.motherboard_id,
      link_component_type: comp_type.component_type
    }

    locals = [
      payload: payload,
      clean_payload: clean_payload,
      comp_id: comp.component_id
    ]

    {:ok, locals}
  end

  test "create/1", %{payload: payload} do
    assert {:ok, _} = CtrlMoboSlots.create(payload)
  end

  describe "find/1" do
    test "success", %{payload: payload} do
      assert {:ok, mobo_slots} = CtrlMoboSlots.create(payload)
      assert {:ok, ^mobo_slots} = CtrlMoboSlots.find(mobo_slots.slot_id)
    end

    test "failure" do
      assert {:error, :notfound} = CtrlMoboSlots.find("")
    end
  end

  test "delete/1 idempotency", %{payload: payload} do
    assert {:ok, mobo_slots} = CtrlMoboSlots.create(payload)
    assert :ok = CtrlMoboSlots.delete(mobo_slots.slot_id)
    assert :ok = CtrlMoboSlots.delete(mobo_slots.slot_id)
  end

  test "link/1 idempotency", %{clean_payload: payload, comp_id: comp_id} do
    assert {:ok, mobo_slots} = CtrlMoboSlots.create(payload)
    assert {:ok, _} = CtrlMoboSlots.link(mobo_slots.slot_id, comp_id)
    assert {:ok, _} = CtrlMoboSlots.link(mobo_slots.slot_id, comp_id)
  end

  test "unlink/1 idempotency", %{payload: payload} do
    assert {:ok, mobo_slots} = CtrlMoboSlots.create(payload)
    assert {:ok, _} = CtrlMoboSlots.unlink(mobo_slots.slot_id)
    assert {:ok, _} = CtrlMoboSlots.unlink(mobo_slots.slot_id)
  end
end