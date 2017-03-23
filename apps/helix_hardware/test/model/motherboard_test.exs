defmodule Helix.Hardware.Model.MotherboardTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Hardware.Model.ComponentSpec
  alias Helix.Hardware.Model.Motherboard

  @moduletag :unit

  describe "component spec" do
    test "requires slots" do
      changeset = Motherboard.validate_spec(%{})

      refute changeset.valid?
      assert [:slots] == Keyword.keys(changeset.errors)
    end

    test "allows several slots" do
      slots = %{
        "0" => slot(),
        "1" => slot(),
        "2" => slot(),
        "3" => slot()
      }

      changeset = Motherboard.validate_spec(%{slots: slots})
      struct_slots = Ecto.Changeset.apply_changes(changeset).slots

      assert changeset.valid?
      assert map_size(slots) == map_size(struct_slots)
    end

    test "requires slots not to be empty" do
      changeset = Motherboard.validate_spec(%{slots: %{}})

      assert :slots in Keyword.keys(changeset.errors)
    end

    test "requires slot to have a numeric string as key" do
      check_spec = fn params ->
        %{slots: params}
        |> Motherboard.validate_spec()
        |> Map.fetch!(:errors)
        |> Keyword.keys()
      end

      assert :slots in check_spec.(%{[1,2] => slot()})
      assert :slots in check_spec.(%{:atom => slot()})
      assert :slots in check_spec.(%{0 => slot()})
      assert :slots in check_spec.(%{"foo" => slot()})
      refute :slots in check_spec.(%{"0" => slot()})
    end

    test "requires a slot to have a valid type" do
      check_spec = fn params ->
        %{slots: %{"0" => params}}
        |> Motherboard.validate_spec()
        |> Map.fetch!(:errors)
        |> Keyword.keys()
      end

      valid_types = ComponentSpec.valid_spec_types()

      assert :slots in check_spec.(%{})
      assert :slots in check_spec.(%{"type" => "FOOBAR"})
      assert :slots in check_spec.(%{"type" => 123})
      assert :slots in check_spec.(%{"type" => %{}})
      assert :slots in check_spec.(%{"type" => []})
      assert :slots in check_spec.(%{"type" => {:foo, :bar}})
      # assert Enum.all?(valid_types, &(:slots not in check_spec.(%{"type" => &1})))
      refute Enum.any?(valid_types, &(:slots in check_spec.(%{"type" => &1})))
    end

    test "allows limit as a post_integer" do
      check_spec = fn params ->
        slot = %{
          "type" => Enum.random(ComponentSpec.valid_spec_types()),
          "limit" => params
        }

        %{slots: %{"0" => slot}}
        |> Motherboard.validate_spec()
        |> Map.fetch!(:errors)
        |> Keyword.keys()
      end

      assert :slots in check_spec.(100..200)
      assert :slots in check_spec.([])
      assert :slots in check_spec.(%{})
      assert :slots in check_spec.(:bar)
      assert :slots in check_spec.("foo")
      assert :slots in check_spec.(-1)
      assert :slots in check_spec.(0)
      refute :slots in check_spec.(1)
    end

    test "is invalid if atleast one slot is improper" do
      check_spec = fn params ->
        %{slots: params}
        |> Motherboard.validate_spec()
        |> Map.fetch!(:errors)
        |> Keyword.keys()
      end

      slots = %{
        "0" => slot(),
        "1" => %{},
        "2" => slot()
      }

      assert :slots in check_spec.(slots)

      slots = %{
        "0" => slot(),
        :foo => slot()
      }

      assert :slots in check_spec.(slots)
    end
  end

  defp slot do
    template = %{
      "limit" => Random.number(1024..2048),
      "type" => Enum.random(ComponentSpec.valid_spec_types())
    }

    possible_outcomes = [["limit", "type"], ["type"]]

    Map.take(template, Enum.random(possible_outcomes))
  end
end
