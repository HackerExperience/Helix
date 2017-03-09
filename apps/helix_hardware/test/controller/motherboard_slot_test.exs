defmodule Helix.Hardware.Controller.MotherboardSlotTest do

  use ExUnit.Case, async: true

  alias HELL.PK
  alias Helix.Hardware.Controller.MotherboardSlot, as: MotherboardSlotController
  alias Helix.Hardware.Model.MotherboardSlot

  alias Helix.Hardware.Factory
  @moduletag :integration

  defp slot_for(motherboard, component) do
    motherboard.slots
    |> Enum.filter(&(&1.link_component_type == component.component_type))
    |> Enum.random()
  end

  describe "find" do
    test "fetching a slot by it's id" do
      mobo = Factory.insert(:motherboard)
      slot = Enum.random(mobo.slots)
      assert {:ok, _} = MotherboardSlotController.find(slot.slot_id)
    end

    test "failure to retrieve a slot when it doesn't exists" do
      assert {:error, :notfound} == MotherboardSlotController.find(PK.pk_for(MotherboardSlot))
    end
  end

  describe "link" do
    test "connecting a component into slot" do
      component = Factory.insert(:component)
      slot =
        :motherboard
        |> Factory.insert()
        |> slot_for(component)

      {:ok, slot} = MotherboardSlotController.link(slot, component)
      assert component.component_id === slot.link_component_id
    end

    test "failure when slot is already used" do
      cpu1 = Factory.insert(:cpu)
      cpu2 = Factory.insert(:cpu)
      slot =
        :motherboard
        |> Factory.insert()
        |> slot_for(cpu1.component)

      {:ok, _} = MotherboardSlotController.link(slot, cpu1.component)

      assert {:error, :slot_already_linked} ==
        MotherboardSlotController.link(slot, cpu2.component)
    end

    test "failure when component is already used" do
      component = Factory.insert(:component)
      slot1 =
        :motherboard
        |> Factory.insert()
        |> slot_for(component)
      slot2 =
        :motherboard
        |> Factory.insert()
        |> slot_for(component)

      {:ok, _} = MotherboardSlotController.link(slot1, component)

      assert {:error, :component_already_linked} ==
        MotherboardSlotController.link(slot2, component)
    end
  end

  test "unlink is idempotent" do
    component = Factory.insert(:component)
    slot =
      :motherboard
      |> Factory.insert()
      |> slot_for(component)

    {:ok, slot} = MotherboardSlotController.link(slot, component)

    assert slot.link_component_id
    assert {:ok, _} = MotherboardSlotController.unlink(slot)
    assert {:ok, _} = MotherboardSlotController.unlink(slot)

    {:ok, slot} = MotherboardSlotController.find(slot.slot_id)

    refute slot.link_component_id
  end
end
