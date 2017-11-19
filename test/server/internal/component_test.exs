defmodule Helix.Server.Internal.ComponentTest do

  use Helix.Test.Case.Integration

  alias Helix.Server.Component.Specable
  alias Helix.Server.Internal.Component, as: ComponentInternal

  alias Helix.Test.Server.Component.Helper, as: ComponentHelper
  alias Helix.Test.Server.Component.Setup, as: ComponentSetup

  describe "create/1" do
    test "inserts the component in the database" do
      spec = ComponentHelper.random_spec()

      assert {:ok, component} = ComponentInternal.create(spec)

      assert component.spec_id == spec.spec_id
      assert component.type == spec.component_type
      assert component.custom == Specable.get_custom(spec)
    end
  end

  describe "fetch/1" do
    test "returns the component from DB" do
      {gen_component, _} = ComponentSetup.component()

      component = ComponentInternal.fetch(gen_component.component_id)

      # Must be identical, so we know for sure that `custom` has been formatted
      assert component == gen_component
    end
  end
end
