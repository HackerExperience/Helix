defmodule Helix.Account.Public.Index.InventoryTest do

  use Helix.Test.Case.Integration

  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Entity.Action.Entity, as: EntityAction
  alias Helix.Account.Public.Index.Inventory, as: InventoryIndex

  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Server.Component.Setup, as: ComponentSetup
  alias Helix.Test.Network.Setup, as: NetworkSetup

  describe "index/1" do
    test "indexes the entire inventory" do
      {server, %{entity: entity}} = ServerSetup.server()

      index = InventoryIndex.index(entity)

      # There are 5 components (initial hardware)
      assert length(index.components) == 5

      [nc] = index.network_connections

      # The NIC used for the NetworkConnection is among the player's components
      assert Enum.find(index.components, &(&1.component_id == nc.nic_id))

      # The NIP described by the NetworkConnection points to the player's server
      assert {:ok, server.server_id} ==
        CacheQuery.from_nip_get_server(nc.network_id, nc.ip)
    end
  end

  describe "render_index/1" do
    test "renders the index to a JSON-friendly format" do
      {_, %{entity: entity}} = ServerSetup.server()

      rendered =
        entity
        |> InventoryIndex.index()
        |> InventoryIndex.render_index()

      assert is_map(rendered.components)
      assert is_list(rendered.network_connections)

      Enum.each(rendered.components, fn {comp_id, component} ->
        assert is_binary(comp_id)

        assert component.custom
        assert is_binary(component.spec_id)
        assert is_binary(component.type)
        assert is_float(component.durability)
        assert is_boolean(component.used?)
      end)

      Enum.each(rendered.network_connections, fn nc ->
        assert is_binary(nc.network_id)
        assert is_binary(nc.ip)
        assert is_binary(nc.name)
        assert is_boolean(nc.used?)
      end)
    end

    test "correctly marks components and connections as used / not used" do
      {_, %{entity: entity}} = ServerSetup.server()

      # Create two components that are not used
      {mobo, _} = ComponentSetup.component(type: :mobo)
      {cpu, _} = ComponentSetup.component(type: :cpu)

      # Link those components to the entity
      assert {:ok, _} = EntityAction.link_component(entity, mobo)
      assert {:ok, _} = EntityAction.link_component(entity, cpu)

      # Create a NetworkConnection that is unused
      {nc, _} = NetworkSetup.Connection.connection(entity_id: entity.entity_id)

      rendered =
        entity
        |> InventoryIndex.index()
        |> InventoryIndex.render_index()

      Enum.each(rendered.components, fn {component_id, component} ->
        if \
          component_id == to_string(mobo.component_id) or
          component_id == to_string(cpu.component_id)
        do
          refute component.used?
        else
          assert component.used?
        end
      end)

      Enum.each(rendered.network_connections, fn rendered_nc ->
        if rendered_nc.ip == nc.ip do
          refute rendered_nc.used?
        else
          assert rendered_nc.used?
        end
      end)
    end
  end
end
