defmodule Helix.Hardware.Service.API.MotherboardTest do

  use Helix.Test.IntegrationCase

  alias HELL.TestHelper.Random
  alias Helix.Hardware.Service.API.Motherboard, as: API
  alias Helix.Hardware.Model.Motherboard
  alias Helix.Hardware.Model.MotherboardSlot
  alias Helix.Hardware.Repo

  alias Helix.Hardware.Factory

  describe "fetch!/1" do
    test "succeeds by component" do
      motherboard = Factory.insert(:motherboard)
      assert %Motherboard{} = API.fetch!(motherboard.component)
    end

    test "raises when input is invalid" do
      assert_raise FunctionClauseError, fn ->
        API.fetch!(%{})
      end

      bogus_motherboard = Factory.build(:motherboard)

      assert_raise Ecto.NoResultsError, fn ->
        API.fetch!(bogus_motherboard.component)
      end
    end
  end

  describe "get_slots/1" do
    test "succeeds by id" do
      motherboard = Factory.insert(:motherboard)

      slots =
        motherboard.slots
        |> Enum.map(&(&1.slot_id))
        |> Enum.sort()

      got =
        motherboard.motherboard_id
        |> API.get_slots()
        |> Enum.map(&(&1.slot_id))
        |> Enum.sort()

      assert slots == got
    end

    test "succeeds by struct" do
      motherboard = Factory.insert(:motherboard)

      slots =
        motherboard.slots
        |> Enum.map(&(&1.slot_id))
        |> Enum.sort()

      got =
        motherboard
        |> API.get_slots()
        |> Enum.map(&(&1.slot_id))
        |> Enum.sort()

      assert slots == got
    end

    test "returns empty list when nothing is found" do
      bogus = Random.pk()
      assert Enum.empty?(API.get_slots(bogus))
    end
  end

  describe "link/2" do
    test "suceeds with valid input" do
      slot = Factory.insert(:motherboard_slot)
      component = Factory.insert(slot.link_component_type)

      assert {:ok, %MotherboardSlot{}} = API.link(slot, component.component)
    end

    test "fails when slot is already in use" do
      slot = Factory.insert(:motherboard_slot)
      component1 = Factory.insert(slot.link_component_type)
      component2 = Factory.insert(slot.link_component_type)

      {:ok, slot} = API.link(slot, component1.component)

      assert {:error, cs} = API.link(slot, component2.component)
      refute cs.valid?
    end

    test "fails when component is already in use" do
      slot1 = Factory.insert(:motherboard_slot)

      slot2 =
        :motherboard
        |> Factory.insert()
        |> API.get_slots()
        |> Enum.filter(&(&1.link_component_type == slot1.link_component_type))
        |> Enum.random()

      component = Factory.insert(slot1.link_component_type)
      API.link(slot1, component.component)

      assert {:error, cs} = API.link(slot2, component.component)
      refute cs.valid?
    end
  end

  describe "unlink/1 is idempotent" do
    # setup
    slot = Factory.insert(:motherboard_slot)

    component = Factory.insert(slot.link_component_type)
    {:ok, slot} = API.link(slot, component.component)

    assert slot.link_component_id

    # exercise
    API.unlink(slot)
    API.unlink(slot)

    # assert
    result = Repo.get(MotherboardSlot, slot.slot_id)
    refute result.link_component_id
  end

  describe "delete/1" do
    test "succeeds by struct" do
      motherboard = Factory.insert(:motherboard)
      assert Repo.get(Motherboard, motherboard.motherboard_id)

      API.delete(motherboard)

      refute Repo.get(Motherboard, motherboard.motherboard_id)
    end

    test "succeeds by id" do
      motherboard = Factory.insert(:motherboard)
      assert Repo.get(Motherboard, motherboard.motherboard_id)

      API.delete(motherboard.motherboard_id)

      refute Repo.get(Motherboard, motherboard.motherboard_id)
    end

    test "is idempotent" do
      motherboard = Factory.insert(:motherboard)
      assert Repo.get(Motherboard, motherboard.motherboard_id)

      API.delete(motherboard.motherboard_id)
      API.delete(motherboard.motherboard_id)

      refute Repo.get(Motherboard, motherboard.motherboard_id)
    end

    test "removes its slots" do
      mobo = Factory.insert(:motherboard)
      slots = API.get_slots(mobo)

      refute Enum.empty?(slots)

      API.delete(mobo)
      slots = API.get_slots(mobo)

      assert Enum.empty?(slots)
    end
  end
end
