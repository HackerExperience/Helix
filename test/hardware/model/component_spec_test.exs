defmodule Helix.Hardware.Model.ComponentSpecTest do

  use ExUnit.Case, async: true

  alias Helix.Hardware.Model.ComponentSpec

  @moduletag :unit

  describe "spec" do
    test "derives all record fields" do
      bogus_input = %{component_type: "CPU", spec_id: "FOOBAR101"}
      changeset = ComponentSpec.create_changeset(bogus_input)

      # Note: the schema defines these three fields and their value is derived
      # from the input spec
      assert [:component_type, :spec_id, :spec] == Keyword.keys(changeset.errors)
    end

    test "derives component_type from spec_type" do
      spec_type = Enum.random(ComponentSpec.valid_spec_types())
      params = %{spec: %{spec_type: spec_type}}
      changeset = ComponentSpec.create_changeset(params)

      refute :component_type in Keyword.keys(changeset.errors)
    end

    test "derives spec_id from spec_code" do
      params = %{spec: %{spec_code: "FOOBAR101"}}
      changeset = ComponentSpec.create_changeset(params)

      refute :spec_id in Keyword.keys(changeset.errors)
      assert "FOOBAR101" == Ecto.Changeset.get_change(changeset, :spec_id)
    end

    test "requires spec_code, spec_type and name" do
      changeset = ComponentSpec.create_changeset(%{})

      {error_msg, meta_errors} = Keyword.fetch!(changeset.errors, :spec)

      assert error_msg =~ "is invalid"
      assert [:spec_code, :spec_type, :name] == Keyword.keys(meta_errors)
    end

    test "requires spec_code to be [A-Z0-9_]{4,lots}" do
      check_spec = fn params ->
        %{spec: %{spec_code: params}}
        |> ComponentSpec.create_changeset()
        |> Map.fetch!(:errors)
        |> Keyword.fetch!(:spec)
        |> elem(1)
        |> Keyword.keys()
      end

      assert :spec_code in check_spec.(12345)
      assert :spec_code in check_spec.(:atom)
      assert :spec_code in check_spec.([1, 2, 3, 4, 5])
      assert :spec_code in check_spec.(%{})
      assert :spec_code in check_spec.("foobar")
      assert :spec_code in check_spec.("I MUST NOT HAVE SPACES")
      assert :spec_code in check_spec.("UNICODEÅ")
      assert :spec_code in check_spec.("X")
      refute :spec_code in check_spec.("XXXX")
      refute :spec_code in check_spec.("0000")
      refute :spec_code in check_spec.("XXX000")
      refute :spec_code in check_spec.("XXX_000")
      refute :spec_code in check_spec.("WELL_THIS_MIGHT_BE_WORTH")
    end

    test "requires name to be a 3-64 string" do
      check_spec = fn params ->
        %{spec: %{name: params}}
        |> ComponentSpec.create_changeset()
        |> Map.fetch!(:errors)
        |> Keyword.fetch!(:spec)
        |> elem(1)
        |> Keyword.keys()
      end

      assert :name in check_spec.(123)
      assert :name in check_spec.(:atom)
      assert :name in check_spec.([1,2])
      assert :name in check_spec.(%{})
      assert :name in check_spec.("x")
      refute :name in check_spec.("xxx")
      refute :name in check_spec.("CPU")
      refute :name in check_spec.("I Might EvEn include UNICODEÅ 😂😂😂")
    end

    test "requires spec_type to be one of a set of predefined values" do
      check_spec = fn params ->
        %{spec: %{spec_type: params}}
        |> ComponentSpec.create_changeset()
        |> Map.fetch!(:errors)
        |> Keyword.fetch!(:spec)
        |> elem(1)
        |> Keyword.keys()
      end

      valid_types = ComponentSpec.valid_spec_types()

      assert :spec_type in check_spec.(123)
      assert :spec_type in check_spec.(:foo)
      assert :spec_type in check_spec.([1,2])
      assert :spec_type in check_spec.(%{})
      assert :spec_type in check_spec.("foobar")
      assert :spec_type in check_spec.("invalid")
      assert :spec_type in check_spec.("NOT VALID")
      assert :spec_type in check_spec.(false)
      refute Enum.any?(valid_types, &(:spec_type in check_spec.(&1)))
    end
  end
end
