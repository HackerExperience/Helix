defmodule Helix.Server.Internal.Component.SpecTest do

  use Helix.Test.Case.Integration

  alias Helix.Server.Model.Component
  alias Helix.Server.Internal.Component, as: ComponentInternal

  describe "fetch/1" do
    test "returns the component spec" do
      spec = ComponentInternal.Spec.fetch(:cpu_001)

      assert %Component.Spec{} = spec
      assert spec.component_type == :cpu
      assert spec.spec_id == :cpu_001
      assert spec.data

      # Common spec attributes
      assert spec.data.name
      assert spec.data.slot
      assert spec.data.price
      assert spec.data.spec_id
      assert spec.data.component_type
    end
  end

  test "returns empty if the spec was not found" do
    refute ComponentInternal.Spec.fetch(:cpu_666)
  end
end
