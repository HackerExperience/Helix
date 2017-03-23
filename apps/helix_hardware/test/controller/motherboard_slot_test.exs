defmodule Helix.Hardware.Controller.MotherboardSlotTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Hardware.Controller.Component, as: ComponentController
  alias Helix.Hardware.Controller.ComponentSpec, as: ComponentSpecController
  alias Helix.Hardware.Controller.Motherboard, as: MotherboardController
  alias Helix.Hardware.Controller.MotherboardSlot, as: MotherboardSlotController
  alias Helix.Hardware.Model.MotherboardSlot
  alias Helix.Hardware.Model.ComponentSpec
  alias Helix.Hardware.Repo

  @moduletag :integration

  setup_all do
    {:ok, spec} = ComponentSpecController.create(motherboard_spec())

    {:ok, motherboard_spec: spec}
  end

  setup context do
    {:ok, mobo} = MotherboardController.create_from_spec(context.motherboard_spec)

    {:ok, mobo: Repo.preload(mobo, :slots)}
  end

  describe "find" do
    test "fetching a slot by it's id", %{mobo: mobo} do
      slot = Enum.random(mobo.slots)
      assert {:ok, _} = MotherboardSlotController.find(slot.slot_id)
    end

    test "failure to retrieve a slot when it doesn't exists" do
      assert {:error, :notfound} === MotherboardSlotController.find(Random.pk())
    end
  end

  describe "link" do
    test "connecting a component into slot", %{mobo: mobo} do
      slot = Enum.random(mobo.slots)

      component = component_for_slot(slot)

      {:ok, slot} = MotherboardSlotController.link(slot, component)
      assert component.component_id === slot.link_component_id
    end

    test "failure when slot is already used", %{mobo: mobo} do
      slot = Enum.random(mobo.slots)

      component0 = component_for_slot(slot)
      component1 = component_for_slot(slot)

      {:ok, slot} = MotherboardSlotController.link(slot, component0)

      assert {:error, :slot_already_linked} === MotherboardSlotController.link(slot, component1)
    end

    test "failure when component is already used", %{mobo: mobo} do
      slot0 = Enum.random(mobo.slots)
      slot1 = Enum.find(mobo.slots, fn e ->
        e.link_component_type == slot0.link_component_type
        and e.slot_id != slot0.slot_id
      end)

      component = component_for_slot(slot0)

       MotherboardSlotController.link(slot0, component)

       assert {:error, :component_already_linked} === MotherboardSlotController.link(slot1, component)
    end
  end

  test "unlink is idempotent", %{mobo: mobo} do
    slot = Enum.random(mobo.slots)

    component = component_for_slot(slot)

    # I think we should make the controllers use the actual structs for all
    # actions but find/fetch/get/search
    {:ok, slot} = MotherboardSlotController.link(slot, component)

    assert Repo.get_by(MotherboardSlot, slot_id: slot.slot_id).link_component_id
    assert {:ok, _} = MotherboardSlotController.unlink(slot)
    assert {:ok, _} = MotherboardSlotController.unlink(slot)
    refute Repo.get_by(MotherboardSlot, slot_id: slot.slot_id).link_component_id
  end

  defp component_for_slot(slot) do
    import Ecto.Query

    ComponentSpec
    |> where([cs], cs.component_type == ^slot.link_component_type)
    |> Repo.all()
    |> Enum.random()
    |> ComponentController.create_from_spec()
    |> elem(1)
  end

  defp motherboard_spec do
    xs =
      ["CPU", "RAM", "HDD", "NIC"]
      |> List.duplicate(3)
      |> Enum.flat_map(&(&1))
      |> Enum.with_index()

    slots = for {component, index} <- xs, into: %{} do
      {to_string(index), %{"type" => component}}
    end

    %{
      "spec_code" => String.upcase(Random.string(min: 12)),
      "spec_type" => "MOBO",
      "name" => Random.string(min: 9),
      "slots" => slots
    }
  end
end
