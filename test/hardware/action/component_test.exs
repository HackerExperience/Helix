defmodule Helix.Hardware.Action.ComponentTest do

  use Helix.Test.IntegrationCase

  alias Helix.Cache.Helper, as: CacheHelper
  alias Helix.Hardware.Action.Component, as: ComponentAction
  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.ComponentSpec
  alias Helix.Hardware.Repo

  alias Helix.Hardware.Factory

  describe "create_from_spec/1" do
    test "succeeds with valid input" do
      spec = Factory.insert(:component_spec)
      assert {:ok, %Component{}} = ComponentAction.create_from_spec(spec)
    end

    test "fails when input is invalid" do
      bogus_spec = %ComponentSpec{
        component_type: :cpu,
        spec: %{
          "spec_code" => "CPU01",
          "spec_type" => "CPU",
          "name" => "Sample CPU 1",
          "clock" => 3000,
          "cores" => 7
        }
      }

      assert {:error, cs} = ComponentAction.create_from_spec(bogus_spec)
      refute cs.valid?
    end
  end

  describe "delete/1" do
    @tag :pending
    test "succeeds by struct" do
      component = Factory.insert(:component)

      assert Repo.get(Component, component.component_id)
      ComponentAction.delete(component)

      refute Repo.get(Component, component.component_id)

      CacheHelper.sync_test()
    end

    @tag :pending
    test "is idempotent" do
      component = Factory.insert(:component)

      assert Repo.get(Component, component.component_id)
      ComponentAction.delete(component)
      ComponentAction.delete(component)

      refute Repo.get(Component, component.component_id)

      CacheHelper.sync_test()
    end
  end
end
