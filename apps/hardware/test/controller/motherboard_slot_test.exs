defmodule HELM.Hardware.Controller.MotherboardSlotTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias HELM.Hardware.Repo
  alias HELM.Hardware.Model.ComponentType
  alias HELM.Hardware.Model.MotherboardSlot
  alias HELM.Hardware.Controller.Component, as: ComponentController
  alias HELM.Hardware.Controller.ComponentSpec, as: SpecController
  alias HELM.Hardware.Controller.Motherboard, as: MotherboardController
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

    slot_type = Enum.random(["ram", "cpu", "hdd"])
    mobo_type = "mobo"

    component_type(slot_type)
    component_type(mobo_type)

    slot_number = Burette.Number.digits(4)
    spec_params = %{
      component_type: mobo_type,
      spec: %{
        spec_type: mobo_type,
        slots: %{
          slot_number => %{type: slot_type}
        }
      }
    }

    {:ok, spec} = SpecController.create(spec_params)

    [
      component_types: types,
      slot_type: slot_type,
      mobo_type: mobo_type,
      spec: spec]
  end

  setup context do
    comp_params = %{
      component_type: context.mobo_type,
      spec_id: context.spec.spec_id}
    {:ok, comp} = ComponentController.create(comp_params)

    mobo_params = %{motherboard_id: comp.component_id}
    {:ok, mobo} = MotherboardController.create(mobo_params)

    slot =
      MotherboardSlotController.find_by(motherboard_id: mobo.motherboard_id)
      |> List.first()

    {:ok, slot: slot, mobo: mobo}
  end

  defp component_type(name) do
    case Repo.get_by(ComponentType, component_type: name) do
      nil ->
        %{component_type: name}
        |> ComponentType.create_changeset()
        |> Repo.insert!()
      component_type ->
        component_type
    end
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

  describe "find" do
    test "fetching a slot by it's id", %{slot: slot} do
      assert {:ok, _} = MotherboardSlotController.find(slot.slot_id)
    end

    test "failure to retrieve a slot when it doesn't exists" do
      assert {:error, :notfound} === MotherboardSlotController.find(Random.pk())
    end
  end

  test "delete is idempotent and removes every slot", %{slot: slot, mobo: mobo} do
    assert Repo.get_by(MotherboardSlot, slot_id: slot.slot_id)
    refute [] === MotherboardSlotController.find_by(motherboard_id: mobo.motherboard_id)

    MotherboardSlotController.delete_all_from_motherboard(mobo.motherboard_id)
    MotherboardSlotController.delete_all_from_motherboard(mobo.motherboard_id)

    refute Repo.get_by(MotherboardSlot, slot_id: slot.slot_id)
    assert [] === MotherboardSlotController.find_by(motherboard_id: mobo.motherboard_id)
  end

  describe "link" do
    test "connecting a component into slot", %{slot: slot} do
      component = component_for(slot)
      {:ok, slot} = MotherboardSlotController.link(slot.slot_id, component.component_id)
      assert component.component_id === slot.link_component_id
    end

    test "failure when slot is already used", %{slot: slot} do
      component = component_for(slot)
      MotherboardSlotController.link(slot.slot_id, component.component_id)
      assert {:error, :slot_already_linked} === MotherboardSlotController.link(slot.slot_id, component.component_id)
    end

    test "failure when component is already used", %{slot: slot, mobo: mobo} do
      component = component_for(slot)

      slot_params = %{
        motherboard_id: mobo.motherboard_id,
        link_component_type: mobo.component_spec.component_type,
        slot_internal_id: Burette.Number.digits(8),
        link_component_id: component.component_id
      }

      MotherboardSlotController.create(slot_params)

      assert {:error, :component_already_linked} === MotherboardSlotController.link(slot.slot_id, component.component_id)
    end
  end

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
