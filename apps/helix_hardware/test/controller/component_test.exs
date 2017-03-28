defmodule Helix.Hardware.Controller.ComponentTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Hardware.Controller.Component, as: ComponentController
  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Repo

  alias Helix.Hardware.Factory

  @moduletag :integration

  describe "fetching" do
    test "succeeds by id" do
      c = Factory.insert(:component)
      assert %Component{} = ComponentController.fetch(c.component_id)
    end

    test "fails when component doesn't exists" do
      refute ComponentController.fetch(Random.pk())
    end
  end

  describe "finding" do
    test "by id list" do
      id_list =
        4
        |> Factory.insert_list(:component)
        |> Enum.map(&(&1.component_id))
        |> Enum.sort()

      found =
        [id: id_list]
        |> ComponentController.find()
        |> Enum.map(&(&1.component_id))
        |> Enum.sort()

      assert id_list == found
    end

    test "by type list" do
      components = Factory.insert_list(4, :component)
      type_list = Enum.map(components, &(&1.component_type))

      found =
        [type: type_list]
        |> ComponentController.find()
        |> Enum.map(&(&1.component_id))

      result =
        components
        |> Enum.map(&(&1.component_id))
        |> Enum.all?(&(&1 in found))

      assert result
    end
  end

  test "deleting is idempotent" do
    component = Factory.insert(:component)

    assert Repo.get(Component, component.component_id)
    ComponentController.delete(component.component_id)
    ComponentController.delete(component.component_id)
    refute Repo.get(Component, component.component_id)
  end
end
