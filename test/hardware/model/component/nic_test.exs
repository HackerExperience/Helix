defmodule Helix.Hardware.Model.Component.NICTest do

  use ExUnit.Case, async: true

  alias Helix.Hardware.Model.Component.NIC

  @moduletag :unit

  describe "component spec" do
    test "requires link" do
      changeset = NIC.validate_spec(%{})

      refute changeset.valid?
      assert [:link] == Keyword.keys(changeset.errors)
    end

    test "link must be a non_neg_integer" do
      check_spec = fn params ->
        params
        |> NIC.validate_spec()
        |> Map.fetch!(:errors)
        |> Keyword.keys()
      end

      assert :link in check_spec.(%{link: "x"})
      assert :link in check_spec.(%{link: :arnesto})
      assert :link in check_spec.(%{link: 3.1415})
      assert :link in check_spec.(%{link: -1})
      refute :link in check_spec.(%{link: 0})
      refute :link in check_spec.(%{link: 1_000})
    end
  end
end
