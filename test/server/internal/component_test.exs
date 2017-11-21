defmodule Helix.Server.Internal.ComponentTest do

  use Helix.Test.Case.Integration

  alias Helix.Server.Component.Specable
  alias Helix.Server.Internal.Component, as: ComponentInternal

  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Server.Component.Helper, as: ComponentHelper
  alias Helix.Test.Server.Component.Setup, as: ComponentSetup

  describe "fetch/1" do
    test "returns the component from DB" do
      {gen_component, _} = ComponentSetup.component()

      component = ComponentInternal.fetch(gen_component.component_id)

      # Must be identical, so we know for sure that `custom` has been formatted
      assert component == gen_component
    end
  end

  describe "create/1" do
    test "inserts the component in the database" do
      spec = ComponentHelper.random_spec()

      custom =
        if spec.component_type == :nic do
          %{network_id: "::", dlk: 100, ulk: 100}
        else
          %{}
        end

      assert {:ok, component} = ComponentInternal.create(spec, custom)

      assert component.spec_id == spec.spec_id
      assert component.type == spec.component_type
      assert component.custom == Specable.create_custom(spec, custom)
    end
  end

  describe "update_custom/2" do
    test "modifies a NIC's network_id or dlk/ulk" do
      {nic, _} = ComponentSetup.component(type: :nic)

      # Initial custom of a NIC is "empty"
      assert nic.custom.network_id == NetworkHelper.internet_id()
      assert nic.custom.dlk == 0
      assert nic.custom.ulk == 0

      new_network_id = NetworkHelper.random_id()

      assert {:ok, new_nic} =
        ComponentInternal.update_custom(nic, %{network_id: new_network_id})

      assert new_nic.custom.network_id == new_network_id

      new_speed = %{dlk: 24, ulk: 24}

      assert {:ok, new_nic} = ComponentInternal.update_custom(nic, new_speed)

      assert new_nic.custom.dlk == new_speed.dlk
      assert new_nic.custom.ulk == new_speed.ulk
     end
  end

  describe "create_initial_components/0" do
    test "creates all initial components" do
      assert {:ok, components} = ComponentInternal.create_initial_components()

      Enum.each(components, fn component ->
        assert ComponentInternal.fetch(component.component_id)
      end)
    end
  end
end
