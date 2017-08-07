defmodule Helix.Hardware.Query.ComponentTest do

  use Helix.Test.IntegrationCase

  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Query.Component, as: ComponentQuery

  alias Helix.Hardware.Factory

  describe "fetch/1" do
    test "succeeds by id" do
      component = Factory.insert(:component)
      assert %Component{} = ComponentQuery.fetch(component.component_id)
    end

    test "fails when component doesn't exist" do
      refute ComponentQuery.fetch(Component.ID.generate())
    end
  end
end
