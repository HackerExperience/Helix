defmodule Helix.Hardware.Controller.ComponentTest do

  use ExUnit.Case, async: true

  alias HELL.PK
  alias Helix.Hardware.Controller.Component, as: ComponentController
  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Repo

  alias Helix.Hardware.Factory

  @moduletag :integration

  describe "fetching" do
    # REVIEW: Refactor me, use fetch instead of find

    test "succeeds by id" do
      c = Factory.insert(:component)
      assert {:ok, _} = ComponentController.find(c.component_id)
    end

    test "fails when component doesn't exists" do
      bogus = PK.pk_for(Component)
      assert {:error, :notfound} == ComponentController.find(bogus)
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
