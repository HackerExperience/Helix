defmodule Helix.Hardware.Model.Component.RAMTest do

  use ExUnit.Case, async: true

  alias Helix.Hardware.Model.Component.RAM

  @moduletag :unit

  describe "component spec" do
    test "requires clock and ram_size" do
      changeset = RAM.validate_spec(%{})

      refute changeset.valid?
      assert [:clock, :ram_size] == Keyword.keys(changeset.errors)
    end

    test "clock must be a non_neg_integer" do
      check_spec = fn params ->
        params
        |> RAM.validate_spec()
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

    test "ram_size must be a non_neg_integer" do
      check_spec = fn params ->
        params
        |> RAM.validate_spec()
        |> Map.fetch!(:errors)
        |> Keyword.keys()
      end

      assert :ram_size in check_spec.(%{ram_size: "x"})
      assert :ram_size in check_spec.(%{ram_size: :arnesto})
      assert :ram_size in check_spec.(%{ram_size: 3.1415})
      assert :ram_size in check_spec.(%{ram_size: -1})
      refute :ram_size in check_spec.(%{ram_size: 0})
      refute :ram_size in check_spec.(%{ram_size: 1_000})
    end
  end
end
