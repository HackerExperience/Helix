defmodule Helix.Server.Internal.Component.SpecTest do

  use Helix.Test.Case.Integration

  alias Helix.Server.Model.Component
  alias Helix.Server.Internal.Component, as: ComponentInternal

  describe "fetch/1" do
    test "returns the component" do
      spec = ComponentInternal.Spec.fetch(:cpu_001)

      assert %Component.Spec{} = spec
      assert spec.component_type == :cpu
      assert spec.spec_id == :cpu_001
      assert spec.spec

      # Common spec attributes
      assert spec.spec.name
      assert spec.spec.slot
      assert spec.spec.price
      assert spec.spec.spec_id
      assert spec.spec.component_type
    end
  end
end
