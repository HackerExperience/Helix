defmodule HELM.Hardware.Controller.MotherboardSlotTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias HELM.Hardware.Repo
  alias HELM.Hardware.Model.ComponentType
  alias HELM.Hardware.Model.MotherboardSlot
  alias HELM.Hardware.Controller.ComponentSpec, as: SpecController
  alias HELM.Hardware.Controller.Component, as: ComponentController
  alias HELM.Hardware.Controller.Motherboard, as: CtrlMobos
  alias HELM.Hardware.Controller.MotherboardSlot, as: MotherboardSlotController

  setup_all do
    # FIXME
    types = case Repo.all(ComponentType) do
      [] ->
        1..5
        |> Enum.map(fn _ -> Burette.Color.name() end)
        |> Enum.uniq()
        |> Enum.map(&ComponentType.create_changeset(%{component_type: &1}))
        |> Enum.map(&Repo.insert!/1)
      ct = [_|_] ->
        ct
    end

    [component_types: types]
  end

  setup context do
    {:ok, mobo} = CtrlMobos.create()

    params = %{
      slot_internal_id: Burette.Number.number(1..1024),
      motherboard_id: mobo.motherboard_id,
      link_component_type: Enum.random(context.component_types).component_type
    }

    {:ok, slot} = MotherboardSlotController.create(params)

    locals = [
      slot: slot
      payload: payload,
      clean_payload: clean_payload,
      comp_id: comp.component_id,
      spec_id: comp_spec.spec_id
    ]

    {:ok, locals}
  end

  defp component_for(slot) do
    p = %{
      component_type: slot.link_component_type,
      spec: %{}
    }
    {:ok, comp_spec} = SpecController.create(p)

    p = %{
      component_type: slot.link_component_type,
      spec_id: comp_spec.spec_id
    }
    {:ok, comp} = ComponentController.create(p)

    comp
  end

  describe "find/1" do
    test "fetching a slot by it's id", %{slot: slot} do
      assert {:ok, _} = MotherboardSlotController.find(slot.slot_id)
    end

    test "failure to retrieve a slot when it doesn't exists" do
      assert {:error, :notfound} === MotherboardSlotController.find(Random.pk())
    end
  end

  test "delete is idempotent", %{slot: slot} do
    assert Repo.get_by(MotherboardSlot, slot_id: slot.slot_id)
    MotherboardSlotController.delete(slot.slot_id)
    MotherboardSlotController.delete(slot.slot_id)
    refute Repo.get_by(MotherboardSlot, slot_id: slot.slot_id)
  end

  describe "update/2" do
    test "change slot component", %{payload: payload, spec_id: spec_id} do
      comp_payload = %{component_type: @component_type, spec_id: spec_id}
      {:ok, comp} = CtrlComps.create(comp_payload)

      assert {:ok, mobo_slots} = CtrlMoboSlots.create(payload)

      payload2 = %{link_component_id: comp.component_id}
      assert {:ok, mobo_slots} = CtrlMoboSlots.update(mobo_slots.slot_id, payload2)
      assert mobo_slots.link_component_id == comp.component_id
    end

    test "slot not found" do
      assert {:error, :notfound} = CtrlMoboSlots.update(IPv6.generate([]), %{})
    end
  end

  # Link/1 should not be idempotent, this is error prone
  # test "link/1 idempotency", %{clean_payload: payload, comp_id: comp_id} do
  #   assert {:ok, mobo_slots} = CtrlMoboSlots.create(payload)
  #   assert {:ok, _} = CtrlMoboSlots.link(mobo_slots.slot_id, comp_id)
  #   assert {:ok, _} = CtrlMoboSlots.link(mobo_slots.slot_id, comp_id)
  # end

  test "unlink is idempotent", %{slot: slot} do
    component = component_for(slot)

    # I think we should make the controllers use the actual structs for all
    # actions but find/fetch/get/search
    MotherboardSlotController.link(slot.slot_id, component.component_id)
    assert Repo.get_by(MotherboardSlot, slot_id: slot.slot_id).link_component_id
    assert {:ok, _} = MotherboardSlotController.unlink(slot.slot_id)
    assert {:ok, _} = MotherboardSlotController.unlink(slot.slot_id)
    refute Repo.get_by(MotherboardSlot, slot_id: slot.slot_id).link_component_id
  end
end