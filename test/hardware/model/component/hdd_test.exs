defmodule Helix.Hardware.Model.Component.HDDTest do

  use ExUnit.Case, async: true

  alias Helix.Hardware.Model.Component.HDD

  @moduletag :unit

  describe "component spec" do
    test "requires hdd_size" do
      changeset = HDD.validate_spec(%{})

      refute changeset.valid?
      assert [:hdd_size] == Keyword.keys(changeset.errors)
    end

    test "hdd_size must be a non_neg_integer" do
      check_spec = fn params ->
        params
        |> HDD.validate_spec()
        |> Map.fetch!(:errors)
        |> Keyword.keys()
      end

      assert :hdd_size in check_spec.(%{hdd_size: "x"})
      assert :hdd_size in check_spec.(%{hdd_size: :arnesto})
      assert :hdd_size in check_spec.(%{hdd_size: 3.1415})
      assert :hdd_size in check_spec.(%{hdd_size: -1})
      refute :hdd_size in check_spec.(%{hdd_size: 0})
      refute :hdd_size in check_spec.(%{hdd_size: 1_000})
    end
  end
end
