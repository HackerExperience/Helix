defmodule Helix.Hardware.Controller.ComponentTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Hardware.Repo
  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.ComponentType
  alias Helix.Hardware.Controller.ComponentSpec, as: SpecController
  alias Helix.Hardware.Controller.Component, as: ComponentController

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

    p = %{
      component_type: type.component_type,
      spec: %{
        spec_code: Random.string(min: 20, max: 20)}}

    {:ok, comp_spec} = SpecController.create(p)

    [component_type: type, component_spec: comp_spec]
  end

  setup context do
    params = %{
      component_type: context.component_type.component_type,
      spec_id: context.component_spec.spec_id
    }

    {:ok, c} = ComponentController.create(params)
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