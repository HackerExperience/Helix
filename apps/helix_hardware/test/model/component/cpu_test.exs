defmodule Helix.Hardware.Model.Component.CPUTest do

  use ExUnit.Case, async: true

  alias Helix.Hardware.Model.Component.CPU

  @moduletag :unit

  describe "component spec" do
    test "requires clock and cores" do
      changeset = CPU.validate_spec(%{})

      refute changeset.valid?
      assert [:clock, :cores] == Keyword.keys(changeset.errors)
    end

    test "clock must be a non_neg_integer" do
      check_spec = fn params ->
        params
        |> CPU.validate_spec()
        |> Map.fetch!(:errors)
        |> Keyword.keys()
      end

      assert :clock in check_spec.(%{clock: "x"})
      assert :clock in check_spec.(%{clock: :arnesto})
      assert :clock in check_spec.(%{clock: 3.1415})
      assert :clock in check_spec.(%{clock: -1})
      refute :clock in check_spec.(%{clock: 0})
      refute :clock in check_spec.(%{clock: 1_000})
    end

    test "cores must be a pos_integer" do
      check_spec = fn params ->
        params
        |> CPU.validate_spec()
        |> Map.fetch!(:errors)
        |> Keyword.keys()
      end

      assert :cores in check_spec.(%{cores: "x"})
      assert :cores in check_spec.(%{cores: :arnesto})
      assert :cores in check_spec.(%{cores: 3.1415})
      assert :cores in check_spec.(%{cores: -1})
      assert :cores in check_spec.(%{cores: 0})
      refute :cores in check_spec.(%{cores: 1_000})
    end
  end
end
