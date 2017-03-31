defmodule Helix.Hardware.Controller.MotherboardSlotTest do

  use ExUnit.Case, async: true

  alias Helix.Hardware.Controller.MotherboardSlot, as: MotherboardSlotController
  alias Helix.Hardware.Model.MotherboardSlot
  alias Helix.Hardware.Repo

  alias Helix.Hardware.Factory

  @moduletag :integration

  def component_for(slot) do
    specialization = Factory.insert(slot.link_component_type)

    specialization.component
  end

  describe "linking" do
    test "links a component to slot" do
      slot =
        :motherboard
        |> Factory.insert()
        |> Map.fetch!(:slots)
        |> Enum.random()

      component = component_for(slot)

      {:ok, slot} = MotherboardSlotController.link(slot, component)
      assert component.component_id == slot.link_component_id
    end

    test "fails when slot is already in use" do
      slot =
        :motherboard
        |> Factory.insert()
        |> Map.fetch!(:slots)
        |> Enum.random()

      component1 = component_for(slot)
      component2 = component_for(slot)

      {:ok, slot} = MotherboardSlotController.link(slot, component1)

      result = MotherboardSlotController.link(slot, component2)
      assert {:error, :slot_already_linked} == result
    end

    test "fails when component is already in use" do
      slot_for = fn motherboard, component ->
        motherboard.slots
        |> Enum.filter(&(&1.link_component_type == component.component_type))
        |> Enum.random()
      end

      component =
        :cpu
        |> Factory.insert()
        |> Map.fetch!(:component)

      slot1 =
        :motherboard
        |> Factory.insert()
        |> slot_for.(component)

      slot2 =
        :motherboard
        |> Factory.insert()
        |> slot_for.(component)

      MotherboardSlotController.link(slot1, component)

      result = MotherboardSlotController.link(slot2, component)
      assert {:error, :component_already_linked} == result
    end
  end

  test "unlink is idempotent" do
    slot =
      :motherboard
      |> Factory.insert()
      |> Map.fetch!(:slots)
      |> Enum.random()

    component = component_for(slot)

    {:ok, slot} = MotherboardSlotController.link(slot, component)

    assert slot.link_component_id
    assert {:ok, _} = MotherboardSlotController.unlink(slot)
    assert {:ok, _} = MotherboardSlotController.unlink(slot)

    slot = Repo.get(MotherboardSlot, slot.slot_id)

    refute slot.link_component_id
  end
end
