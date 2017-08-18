defmodule Helix.Hardware.Internal.ComponentTest do

  use Helix.Test.Case.Integration

  alias Helix.Test.Cache.Helper, as: CacheHelper
  alias Helix.Hardware.Internal.Component, as: ComponentInternal
  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Repo

  alias Helix.Test.Hardware.Factory

  describe "fetching" do
    test "succeeds by id" do
      c = Factory.insert(:component)
      assert %Component{} = ComponentInternal.fetch(c.component_id)
    end

    test "fails when component doesn't exists" do
      refute ComponentInternal.fetch(Component.ID.generate())
    end
  end

  test "delete/1 removes entry" do
    component = Factory.insert(:component)

    assert Repo.get(Component, component.component_id)
    ComponentInternal.delete(component)
    refute Repo.get(Component, component.component_id)

    CacheHelper.sync_test()
  end
end
