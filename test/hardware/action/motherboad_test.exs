defmodule Helix.Hardware.Action.MotherboardTest do

  use Helix.Test.IntegrationCase

  alias Helix.Cache.Helper, as: CacheHelper
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

      CacheHelper.sync_test()
    end

    test "fails when slot is already in use" do
      slot = Factory.insert(:motherboard_slot)
      component1 = Factory.insert(slot.link_component_type)
      component2 = Factory.insert(slot.link_component_type)

      {:ok, slot} = MotherboardAction.link(slot, component1.component)

      assert {:error, cs} = MotherboardAction.link(slot, component2.component)
      refute cs.valid?

      CacheHelper.sync_test()
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

      CacheHelper.sync_test()
    end
  end

  describe "unlink/1 is idempotent" do
    slot = Factory.insert(:motherboard_slot)

    component = Factory.insert(slot.link_component_type)
    {:ok, slot} = MotherboardAction.link(slot, component.component)

    assert slot.link_component_id

    MotherboardAction.unlink(slot)
    MotherboardAction.unlink(slot)

    result = Repo.get(MotherboardSlot, slot.slot_id)
    refute result.link_component_id

    CacheHelper.sync_test()
  end

  describe "delete/1" do
    test "succeeds with valid data" do
      motherboard = Factory.insert(:motherboard)
      assert Repo.get(Motherboard, motherboard.motherboard_id)

      MotherboardAction.delete(motherboard)

      refute Repo.get(Motherboard, motherboard.motherboard_id)

      CacheHelper.sync_test()
    end

    @tag :pending
    test "is idempotent" do
      motherboard = Factory.insert(:motherboard)
      assert Repo.get(Motherboard, motherboard.motherboard_id)

      MotherboardAction.delete(motherboard.motherboard_id)
      MotherboardAction.delete(motherboard.motherboard_id)

      refute Repo.get(Motherboard, motherboard.motherboard_id)

      CacheHelper.sync_test()
    end

    test "removes its slots" do
      mobo = Factory.insert(:motherboard)
      slots = MotherboardQuery.get_slots(mobo)

      refute Enum.empty?(slots)

      MotherboardAction.delete(mobo)

      slots = MotherboardQuery.get_slots(mobo)
      assert Enum.empty?(slots)

      CacheHelper.sync_test()
    end
  end
end
