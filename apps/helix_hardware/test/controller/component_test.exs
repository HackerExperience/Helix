defmodule Helix.Hardware.Controller.ComponentTest do

  use ExUnit.Case, async: true

  alias HELL.PK
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
      bogus = PK.pk_for(Component)
      refute ComponentController.fetch(bogus)
    end
  end

  describe "finding" do
    test "by id list" do
      id_list =
        4
        |> Factory.insert_list(:component)
        |> Enum.map(&(&1.component_id))

      found =
        [id: id_list]
        |> ComponentController.find()
        |> Enum.map(&(&1.component_id))

      assert Enum.empty?(id_list -- found)
    end

    test "by type list" do
      components = Factory.insert_list(4, :component)
      type_list = Enum.map(components, &(&1.component_type))
      id_list = Enum.map(components, &(&1.component_id))

      found =
        [type: type_list]
        |> ComponentController.find()
        |> Enum.map(&(&1.component_id))

      result = Enum.reject(id_list, &(&1 in found))
      assert Enum.empty?(result)
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
