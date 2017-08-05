defmodule Helix.Hardware.Query.ComponentSpecTest do

  use Helix.Test.IntegrationCase

  alias Helix.Hardware.Model.ComponentSpec
  alias Helix.Hardware.Query.ComponentSpec, as: ComponentSpecQuery

  alias Helix.Hardware.Factory

  describe "fetch/1" do
    test "succeeds by id" do
      cs = Factory.insert(:component_spec)
      assert %ComponentSpec{} = ComponentSpecQuery.fetch(cs.spec_id)
    end

    test "fails when it doesn't exist" do
      refute ComponentSpecQuery.fetch("foobarbaz")
    end
  end
end
