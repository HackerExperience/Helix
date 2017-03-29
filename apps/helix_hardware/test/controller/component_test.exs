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
    test "by id" do
      component = Factory.insert(:component)
      [found] = ComponentController.find(id: component.component_id)

      assert component.component_id == found.component_id
    end

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

    test "by type" do
      type = Factory.random_component_type()
      components = Factory.insert_list(3, :component, component_type: type)

      found = ComponentController.find(type: type)
      found_ids = Enum.map(found, &(&1.component_id))

      assert Enum.all?(components, &(&1.component_id in found_ids))
      assert Enum.all?(found, &(&1.component_type == type))
    end

    test "by type list" do
      components = Factory.insert_list(4, :component)
      type_list = Enum.map(components, &(&1.component_type))

      found = ComponentController.find(type: type_list)
      found_ids = Enum.map(found, &(&1.component_id))

      assert Enum.all?(components, &(&1.component_id in found_ids))
      assert Enum.all?(found, &(&1.component_type in type_list))
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
