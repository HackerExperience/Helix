defmodule Helix.Account.Public.Index.Inventory do

  import HELL.Macros

  alias HELL.Utils
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Component
  alias Helix.Server.Query.Component, as: ComponentQuery
  alias Helix.Server.Query.Motherboard, as: MotherboardQuery

  @type index ::
    %{
      components: component_index,
      network_connections: network_connection_index
    }

  @type rendered_index ::
    %{
      components: rendered_component_index,
      network_connections: rendered_network_connection_index
    }

  @typep component_index :: [Component.t]
  @typep network_connection_index :: [Network.Connection.t]

  @typep rendered_component_index ::
    %{component_id :: String.t => rendered_component}

  @typep rendered_component ::
    %{
      spec_id: String.t,
      durability: float,
      used?: boolean,
      type: String.t,
      custom: %{term => String.t}
    }

  @typep rendered_network_connection_index ::
    [rendered_network_connection]

  @typep rendered_network_connection ::
    %{
      network_id: String.t,
      ip: String.t,
      name: String.t,
      used?: boolean
    }

  @spec index(Entity.t) ::
    index
  def index(entity = %Entity{}) do
    %{
      components: get_components(entity),
      network_connections: get_network_connections(entity)
    }
  end

  @spec get_components(Entity.t) ::
    component_index
  defp get_components(entity) do
    entity
    |> EntityQuery.get_components()
    |> Enum.map(&(ComponentQuery.fetch(&1.component_id)))
  end

  @spec get_network_connections(Entity.t) ::
    network_connection_index
  defp get_network_connections(entity) do
    entity.entity_id
    |> EntityQuery.get_network_connections()
  end

  @spec render_index(index) ::
    rendered_index
  def render_index(index) do
    %{
      components: render_components(index.components),
      network_connections: render_network_connections(index.network_connections)
    }
  end

  @spec render_components(component_index) ::
    rendered_component_index
  defp render_components(components) do
    linked_components = get_linked_components(components)

    Enum.reduce(components, %{}, fn component, acc ->
      component_id = component.component_id |> to_string()

      %{}
      |> Map.put(component_id, render_component(component, linked_components))
      |> Map.merge(acc)
    end)
  end

  @spec render_component(Component.t, [Component.t]) ::
    rendered_component
  defp render_component(component, linked_components) do
    %{
      spec_id: to_string(component.spec_id),
      type: to_string(component.type),
      custom: Utils.stringify_map(component.custom),
      used?: component in linked_components,
      durability: 1.0  # TODO: #339
    }
  end

  @spec render_network_connections(network_connection_index) ::
    rendered_network_connection_index
  defp render_network_connections(network_connections) do
    Enum.reduce(network_connections, [], fn nc, acc ->
      acc ++ [render_network_connection(nc)]
    end)
  end

  @spec render_network_connection(Network.Connection.t) ::
    rendered_network_connection
  defp render_network_connection(nc) do
    %{
      network_id: nc.network_id |> to_string(),
      ip: nc.ip,
      name: "Internet",
      used?: not is_nil(nc.nic_id)
    }
  end

  docp """
  Iterates over all components owned by the user and figures out which ones are
  used (i.e. are linked to a motherboard).

  Note that, for our indexing purpose, a motherboard with linked components to
  it is marked as a linked component itself, so the motherboard entry returned
  to the client also tells whether it is being used or not.
  """
  defp get_linked_components(components) do
    components

    # Fetches all motherboards
    |> Enum.reduce([], fn component, acc ->
      if component.type == :mobo do
        motherboard = MotherboardQuery.fetch(component.component_id)

        # Fetching a motherboard may return empty if there are no components
        # linked to it, hence this check.
        if motherboard do
          acc ++ [{MotherboardQuery.fetch(component.component_id), component}]
        else
          acc
        end
      else
        acc
      end
    end)

    # From these mobos, accumulates the linked components (and the mobo itself)
    |> Enum.reduce([], fn {motherboard, mobo}, acc ->
      acc ++ MotherboardQuery.get_components(motherboard) ++ [mobo]
    end)

    # Flatten earth
    |> List.flatten()
  end
end
