defmodule Helix.Hardware.Controller.MotherboardSlotTest do

  use ExUnit.Case, async: true

  alias HELL.PK
  alias Helix.Hardware.Controller.MotherboardSlot, as: MotherboardSlotController
  alias Helix.Hardware.Model.MotherboardSlot

  alias Helix.Hardware.Factory

  @moduletag :integration

  def component_for(slot) do
    specialization =
      slot.link_component_type
      |> String.to_atom()
      |> Factory.insert()

    specialization.component
  end

  describe "fetching" do
    # REVIEW: Refactor me, use fetch instead of find

    test "succeeds by id" do
      slot = Factory.insert(:motherboard_slot)
      assert {:ok, _} = MotherboardSlotController.find(slot.slot_id)
    end

    test "fails when slot doesn't exists" do
      bogus = PK.pk_for(MotherboardSlot)
      assert {:error, :notfound} == MotherboardSlotController.find(bogus)
    end
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

    {:ok, slot} = MotherboardSlotController.find(slot.slot_id)

    refute slot.link_component_id
  end
end
