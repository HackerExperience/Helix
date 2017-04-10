defmodule Helix.Hardware.Controller.MotherboardTest do

  use Helix.Test.IntegrationCase

  alias Helix.Hardware.Controller.Motherboard, as: MotherboardController
  alias Helix.Hardware.Model.ComponentType
  alias Helix.Hardware.Model.Motherboard
  alias Helix.Hardware.Model.MotherboardSlot
  alias Helix.Hardware.Repo

  alias Helix.Hardware.Factory

  defp component_of_type(type) do
    specialized_component = Factory.insert(type)

    specialized_component.component
  end

  def component_for(slot) do
    specialization = Factory.insert(slot.link_component_type)

    specialization.component
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

  describe "linking" do
    test "links a component to slot" do
      slot =
        :motherboard
        |> Factory.insert()
        |> Map.fetch!(:slots)
        |> Enum.random()

      component = component_for(slot)

      {:ok, slot} = MotherboardController.link(slot, component)
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

      {:ok, slot} = MotherboardController.link(slot, component1)

      {:error, cs} = MotherboardController.link(slot, component2)
      assert :link_component_id in Keyword.keys(cs.errors)
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

      MotherboardController.link(slot1, component)

      {:error, cs} = MotherboardController.link(slot2, component)
      assert :link_component_id in Keyword.keys(cs.errors)
    end
  end

  test "unlink is idempotent" do
    slot =
      :motherboard
      |> Factory.insert()
      |> Map.fetch!(:slots)
      |> Enum.random()

    component = component_for(slot)

    {:ok, slot} = MotherboardController.link(slot, component)

    assert slot.link_component_id
    assert {:ok, _} = MotherboardController.unlink(slot)
    assert {:ok, _} = MotherboardController.unlink(slot)

    slot = Repo.get(MotherboardSlot, slot.slot_id)

    refute slot.link_component_id
  end

  test "unlinking every component from a motherboard" do
    mobo = Factory.insert(:motherboard)

    mobo.slots
    |> Enum.take_random(3)
    |> Enum.each(fn slot ->
      type = slot.link_component_type
      component = component_of_type(type)

      MotherboardController.link(slot, component)
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
