defmodule Helix.Hardware.Internal.ComponentTest do

  use Helix.Test.IntegrationCase

  alias HELL.TestHelper.Random
  alias Helix.Cache.Helper, as: CacheHelper
  alias Helix.Hardware.Internal.Component, as: ComponentInternal
  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Repo

  alias Helix.Hardware.Factory

  describe "fetching" do
    test "succeeds by id" do
      c = Factory.insert(:component)
      assert %Component{} = ComponentInternal.fetch(c.component_id)
    end

    test "fails when component doesn't exists" do
      refute ComponentInternal.fetch(Random.pk())
    end
  end

  test "deleting is idempotent" do
    component = Factory.insert(:component)

    assert Repo.get(Component, component.component_id)
    ComponentInternal.delete(component.component_id)
    ComponentInternal.delete(component.component_id)
    refute Repo.get(Component, component.component_id)

    CacheHelper.sync_test()
  end
end
