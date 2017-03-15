defmodule Helix.Hardware.Controller.MotherboardTest do

  use ExUnit.Case, async: true

  alias Helix.Hardware.Controller.Motherboard, as: MotherboardController
  alias Helix.Hardware.Controller.MotherboardSlot, as: MotherboardSlotController

  alias Helix.Hardware.Factory

  @moduletag :integration

  describe "motherboard fetching" do
    test "succeeds by id" do
      mobo = Factory.insert(:motherboard)

      assert {:ok, found} = MotherboardController.find(mobo.motherboard_id)
      assert mobo.motherboard_id == found.motherboard_id
    end

    test "fails when motherboard doesn't exists" do
      mobo = Factory.build(:motherboard)

      assert {:error, :notfound} == MotherboardController.find(mobo.motherboard_id)
    end
  end

  test "unlinking every component from a motherboard" do
    mobo = Factory.insert(:motherboard)

    mobo.slots
    |> Enum.take_random(3)
    |> Enum.each(fn slot ->
      type = slot.link_component_type
      component = Factory.component_of_type(type)

      MotherboardSlotController.link(slot, component)
    end)

    MotherboardController.unlink_components_from_motherboard(mobo)

    non_empty_slots =
      mobo
      |> MotherboardController.get_slots()
      |> Enum.reject(&is_nil(&1.link_component_id))

    assert [] == non_empty_slots
  end

  describe "motherboard deleting" do
    test "is idempotent" do
      mobo = Factory.insert(:motherboard)

      assert {:ok, _} = MotherboardController.find(mobo.motherboard_id)

      MotherboardController.delete(mobo.motherboard_id)
      MotherboardController.delete(mobo.motherboard_id)

      assert {:error, :notfound} =
        MotherboardController.find(mobo.motherboard_id)
    end

    test "removes its slots" do
      mobo = Factory.insert(:motherboard)

      refute [] == MotherboardController.get_slots(mobo.motherboard_id)

      MotherboardController.delete(mobo.motherboard_id)

      assert [] == MotherboardController.get_slots(mobo.motherboard_id)
    end
  end
end
