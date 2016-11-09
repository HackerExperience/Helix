defmodule HELM.Hardware.Controller.MotherboardSlotTest do
  use ExUnit.Case

  alias HELL.IPv6
  alias HELL.TestHelper.Random, as: HRand
  alias HELM.Hardware.Controller.ComponentType, as: CtrlCompType
  alias HELM.Hardware.Controller.ComponentSpec, as: CtrlCompSpec
  alias HELM.Hardware.Controller.Component, as: CtrlComps
  alias HELM.Hardware.Controller.Motherboard, as: CtrlMobos
  alias HELM.Hardware.Controller.MotherboardSlot, as: CtrlMoboSlots

  setup do
    type_name = HRand.string()
    spec_payload = %{component_type: type_name, spec: %{}}

    {:ok, comp_type} = CtrlCompType.create(type_name)
    {:ok, comp_spec} = CtrlCompSpec.create(spec_payload)

    comp_payload = %{component_type: comp_type.component_type, spec_id: comp_spec.spec_id}

    {:ok, comp} = CtrlComps.create(comp_payload)
    {:ok, mobo} = CtrlMobos.create()

    payload = %{
      slot_internal_id: HRand.number(1..1024),
      motherboard_id: mobo.motherboard_id,
      link_component_type: comp_type.component_type,
      link_component_id: comp.component_id
    }

    clean_payload = %{
      slot_internal_id: HRand.number(1..1024),
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
      assert {:error, :notfound} = CtrlMoboSlots.find(IPv6.generate([]))
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