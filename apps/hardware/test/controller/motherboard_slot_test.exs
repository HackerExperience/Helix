defmodule Helix.Hardware.Controller.MotherboardSlotTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Hardware.Repo
  alias Helix.Hardware.Model.ComponentType
  alias Helix.Hardware.Model.MotherboardSlot
  alias Helix.Hardware.Controller.Component, as: ComponentController
  alias Helix.Hardware.Controller.ComponentSpec, as: ComponentSpecController
  alias Helix.Hardware.Controller.Motherboard, as: MotherboardController
  alias Helix.Hardware.Controller.MotherboardSlot, as: MotherboardMotherboardSlotController

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

    component_type(slot_type)
    component_type("mobo")

    slot_number = Burette.Number.digits(4)
    spec_params = %{
      component_type: "mobo",
      spec: %{
        spec_type: "mobo",
        spec_code: Random.string(min: 20, max: 20),
        slots: %{
          slot_number => %{type: slot_type}
        }
      }
    }

    {:ok, spec} = ComponentSpecController.create(spec_params)

    [
      component_types: types,
      slot_type: slot_type,
      spec: spec]
  end

  setup %{spec: spec} do
    {:ok, mobo} = create_motherboard(spec.spec_id)
    slot =
      mobo.motherboard_id
      |> MotherboardController.get_slots()
      |> List.first()

    {:ok, slot: slot, mobo: mobo}
  end

  defp create_motherboard(spec_id) do
    comp_params = %{
      component_type: "mobo",
      spec_id: spec_id}
    {:ok, comp} = ComponentController.create(comp_params)

    mobo_params = %{motherboard_id: comp.component_id}
    {:ok, mobo} = MotherboardController.create(mobo_params)
    mobo = Repo.preload(mobo, :component_spec)

    {:ok, mobo}
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
      spec: %{spec_code: Random.string(min: 20, max: 20)}
    }
    {:ok, comp_spec} = ComponentSpecController.create(p)

    p = %{
      component_type: slot.link_component_type,
      spec_id: comp_spec.spec_id
    }
    {:ok, comp} = ComponentController.create(p)

    comp
  end

  describe "find" do
    test "fetching a slot by it's id", %{slot: slot} do
      assert {:ok, _} = MotherboardMotherboardSlotController.find(slot.slot_id)
    end

    test "failure to retrieve a slot when it doesn't exists" do
      assert {:error, :notfound} === MotherboardMotherboardSlotController.find(Random.pk())
    end
  end

  describe "link" do
    test "connecting a component into slot", %{slot: slot} do
      component = component_for(slot)
      {:ok, slot} = MotherboardMotherboardSlotController.link(slot.slot_id, component.component_id)
      assert component.component_id === slot.link_component_id
    end

    test "failure when slot is already used", %{slot: slot} do
      component = component_for(slot)
      MotherboardMotherboardSlotController.link(slot.slot_id, component.component_id)
      assert {:error, :slot_already_linked} === MotherboardMotherboardSlotController.link(slot.slot_id, component.component_id)
    end

    test "failure when component is already used", context do
      %{slot: slot0, mobo: mobo} = context
      {:ok, mobo} = create_motherboard(mobo.component.spec_id)

      slot1 =
        mobo.motherboard_id
        |> MotherboardController.get_slots()
        |> Enum.find(&(&1.link_component_type == slot0.link_component_type))

       component = component_for(slot0)
       MotherboardMotherboardSlotController.link(slot0.slot_id, component.component_id)

       assert {:error, :component_already_linked} === MotherboardMotherboardSlotController.link(slot1.slot_id, component.component_id)
    end
  end

  test "unlink is idempotent", %{slot: slot} do
    component = component_for(slot)

    # I think we should make the controllers use the actual structs for all
    # actions but find/fetch/get/search
    MotherboardMotherboardSlotController.link(slot.slot_id, component.component_id)
    assert Repo.get_by(MotherboardSlot, slot_id: slot.slot_id).link_component_id
    assert {:ok, _} = MotherboardMotherboardSlotController.unlink(slot.slot_id)
    assert {:ok, _} = MotherboardMotherboardSlotController.unlink(slot.slot_id)
    refute Repo.get_by(MotherboardSlot, slot_id: slot.slot_id).link_component_id
  end
end
