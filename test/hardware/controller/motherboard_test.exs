defmodule Helix.Hardware.Controller.MotherboardTest do

  use ExUnit.Case, async: true

  alias Helix.Hardware.Controller.Motherboard, as: MotherboardController
  alias Helix.Hardware.Controller.MotherboardSlot, as: MotherboardSlotController
  alias Helix.Hardware.Model.ComponentType
  alias Helix.Hardware.Model.Motherboard
  alias Helix.Hardware.Repo

  alias Helix.Hardware.Factory

  @moduletag :integration

  defp component_of_type(type) do
    specialized_component = Factory.insert(type)

    specialized_component.component
  end

  describe "fetching" do
    test "succeeds by id" do
      mobo = Factory.insert(:motherboard)
      assert %Motherboard{} = MotherboardController.fetch!(mobo.component)
    end

    test "raises Ecto.NoResultsError when motherboard doesn't exists" do
      bogus = Factory.build(:motherboard)

      assert_raise Ecto.NoResultsError, fn ->
        MotherboardController.fetch!(bogus.component)
      end
    end

    test "raises FunctionClauseError if component is not of a motherboard" do
      bogus =
        ComponentType.possible_types()
        |> Enum.reject(&(&1 == :mobo))
        |> Enum.random()
        |> component_of_type()

      assert_raise FunctionClauseError, fn ->
        MotherboardController.fetch!(bogus)
      end
    end
  end

  test "unlinking every component from a motherboard" do
    mobo = Factory.insert(:motherboard)

    mobo.slots
    |> Enum.take_random(3)
    |> Enum.each(fn slot ->
      type = slot.link_component_type
      component = component_of_type(type)

      MotherboardSlotController.link(slot, component)
    end)

    MotherboardController.unlink_components_from_motherboard(mobo)

    unused_slot? = &is_nil(&1.link_component_id)

    slots = MotherboardController.get_slots(mobo)
    assert Enum.all?(slots, unused_slot?)
  end

  describe "motherboard deleting" do
    test "is idempotent" do
      mobo = Factory.insert(:motherboard)

      assert Repo.get(Motherboard, mobo.motherboard_id)

      MotherboardController.delete(mobo.motherboard_id)
      MotherboardController.delete(mobo.motherboard_id)

      refute Repo.get(Motherboard, mobo.motherboard_id)
    end

    test "removes its slots" do
      mobo = Factory.insert(:motherboard)

      slots = MotherboardController.get_slots(mobo.motherboard_id)
      refute Enum.empty?(slots)

      MotherboardController.delete(mobo.motherboard_id)

      slots = MotherboardController.get_slots(mobo.motherboard_id)
      assert Enum.empty?(slots)
    end
  end
end
