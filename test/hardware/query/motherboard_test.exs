defmodule Helix.Hardware.Query.MotherboardTest do

  use Helix.Test.IntegrationCase

  alias HELL.TestHelper.Random
  alias Helix.Hardware.Query.Motherboard, as: MotherboardQuery
  alias Helix.Hardware.Model.Motherboard

  alias Helix.Hardware.Factory

  describe "fetch!/1" do
    test "succeeds by component" do
      motherboard = Factory.insert(:motherboard)
      assert %Motherboard{} = MotherboardQuery.fetch!(motherboard.component)
    end

    test "raises when input is invalid" do
      assert_raise FunctionClauseError, fn ->
        MotherboardQuery.fetch!(%{})
      end

      bogus_motherboard = Factory.build(:motherboard)

      assert_raise Ecto.NoResultsError, fn ->
        MotherboardQuery.fetch!(bogus_motherboard.component)
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
        |> MotherboardQuery.get_slots()
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
        |> MotherboardQuery.get_slots()
        |> Enum.map(&(&1.slot_id))
        |> Enum.sort()

      assert slots == got
    end

    test "returns empty list when nothing is found" do
      bogus = Random.pk()
      assert Enum.empty?(MotherboardQuery.get_slots(bogus))
    end
  end
end
