defmodule Helix.Hardware.Controller.ComponentTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Hardware.Controller.ComponentSpec, as: ComponentSpecController
  alias Helix.Hardware.Controller.Component, as: ComponentController
  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.ComponentSpec
  alias Helix.Hardware.Repo

  @moduletag :integration

  setup_all do
    cs = case Repo.all(ComponentSpec) do
      [] ->
        p = %{
          "spec_code": "SMPCPU1",
          "spec_type": "CPU",
          "name": "Sample CPU 1",
          "clock": 3000,
          "cores": 7
        }


        {:ok, comp_spec} = ComponentSpecController.create(p)

        comp_spec
      cs = [_|_] ->
        Enum.random(cs)
    end

    {:ok, component_spec: cs}
  end

  setup context do
    {:ok, c} = ComponentController.create_from_spec(context.component_spec)

    {:ok, component: c}
  end

  describe "find" do
    test "fetching a component by id", %{component: component} do
      assert {:ok, _} = ComponentController.find(component.component_id)
    end

    test "fails if component doesn't exists" do
      assert {:error, :notfound} === ComponentController.find(Random.pk())
    end
  end

  test "delete is idempotent", %{component: component} do
    assert Repo.get_by(Component, component_id: component.component_id)
    ComponentController.delete(component.component_id)
    ComponentController.delete(component.component_id)
    refute Repo.get_by(Component, component_id: component.component_id)
  end
end