defmodule Helix.Hardware.Controller.ComponentSpecTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Hardware.Repo
  alias Helix.Hardware.Model.ComponentSpec
  alias Helix.Hardware.Model.ComponentType
  alias Helix.Hardware.Controller.ComponentSpec, as: SpecController

  setup_all do
    # FIXME
    type = case Repo.all(ComponentType) do
      [] ->
        %{component_type: Burette.Color.name()}
        |> ComponentType.create_changeset()
        |> Repo.insert!()
      ct = [_|_] ->
        Enum.random(ct)
    end

    [component_type: type]
  end

  setup context do
    component_spec =
      %{
        component_type: context.component_type.component_type,
        spec: %{spec_code: Random.string(min: 20, max: 20)}}
      |> ComponentSpec.create_changeset()
      |> Repo.insert!()

    {:ok, component_spec: component_spec}
  end

  describe "find" do
    test "fetching component_spec by id", %{component_spec: cs} do
      assert {:ok, _} = SpecController.find(cs.spec_code)
    end

    test "returns error when spec doesn't exists" do
      assert {:error, :notfound} === SpecController.find(Random.pk())
    end
  end

  describe "update" do
    test "overrides the spec", %{component_spec: cs} do
      update_params = %{spec: %{test: Burette.Color.name()}}
      {:ok, spec} = SpecController.update(cs.spec_code, update_params)

      assert update_params.spec === spec.spec
    end

    test "returns error when spec doesn't exists" do
      assert {:error, :notfound} === SpecController.update(HELL.TestHelper.Random.pk(), %{})
    end
  end

  test "delete is idempotent", %{component_spec: cs} do
    assert Repo.get_by(ComponentSpec, spec_code: cs.spec_code)
    SpecController.delete(cs.spec_code)
    SpecController.delete(cs.spec_code)
    SpecController.delete(cs.spec_code)
    refute Repo.get_by(ComponentSpec, spec_code: cs.spec_code)
  end
end