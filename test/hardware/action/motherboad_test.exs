defmodule Helix.Hardware.Action.MotherboardTest do

  use Helix.Test.IntegrationCase

  alias Helix.Hardware.Action.Motherboard, as: MotherboardAction
  alias Helix.Hardware.Model.Motherboard
  alias Helix.Hardware.Model.MotherboardSlot
  alias Helix.Hardware.Query.Motherboard, as: MotherboardQuery
  alias Helix.Hardware.Repo

  alias Helix.Hardware.Factory

  describe "link/2" do
    test "suceeds with valid input" do
      slot = Factory.insert(:motherboard_slot)
      component = Factory.insert(slot.link_component_type)

      assert {:ok, %MotherboardSlot{}} = MotherboardAction.link(
        slot,
        component.component)
    end

    test "fails when slot is already in use" do
      slot = Factory.insert(:motherboard_slot)
      component1 = Factory.insert(slot.link_component_type)
      component2 = Factory.insert(slot.link_component_type)

      {:ok, slot} = MotherboardAction.link(slot, component1.component)

      assert {:error, cs} = MotherboardAction.link(slot, component2.component)
      refute cs.valid?
    end

    test "fails when component is already in use" do
      slot1 = Factory.insert(:motherboard_slot)

      slot2 =
        :motherboard
        |> Factory.insert()
        |> MotherboardQuery.get_slots()
        |> Enum.filter(&(&1.link_component_type == slot1.link_component_type))
        |> Enum.random()

      component = Factory.insert(slot1.link_component_type)
      MotherboardAction.link(slot1, component.component)

      assert {:error, cs} = MotherboardAction.link(slot2, component.component)
      refute cs.valid?
    end
  end

  describe "unlink/1 is idempotent" do
    # setup
    slot = Factory.insert(:motherboard_slot)

    component = Factory.insert(slot.link_component_type)
    {:ok, slot} = MotherboardAction.link(slot, component.component)

    assert slot.link_component_id

    # exercise
    MotherboardAction.unlink(slot)
    MotherboardAction.unlink(slot)

    # assert
    result = Repo.get(MotherboardSlot, slot.slot_id)
    refute result.link_component_id
  end

  describe "delete/1" do
    test "succeeds by struct" do
      motherboard = Factory.insert(:motherboard)
      assert Repo.get(Motherboard, motherboard.motherboard_id)

      MotherboardAction.delete(motherboard)

      refute Repo.get(Motherboard, motherboard.motherboard_id)
    end

    test "succeeds by id" do
      motherboard = Factory.insert(:motherboard)
      assert Repo.get(Motherboard, motherboard.motherboard_id)

      MotherboardAction.delete(motherboard.motherboard_id)

      refute Repo.get(Motherboard, motherboard.motherboard_id)
    end

    test "is idempotent" do
      motherboard = Factory.insert(:motherboard)
      assert Repo.get(Motherboard, motherboard.motherboard_id)

      MotherboardAction.delete(motherboard.motherboard_id)
      MotherboardAction.delete(motherboard.motherboard_id)

      refute Repo.get(Motherboard, motherboard.motherboard_id)
    end

    test "removes its slots" do
      mobo = Factory.insert(:motherboard)
      slots = MotherboardQuery.get_slots(mobo)

      refute Enum.empty?(slots)

      MotherboardAction.delete(mobo)
      slots = MotherboardQuery.get_slots(mobo)

      assert Enum.empty?(slots)
    end
  end
end
