defmodule Helix.Entity.Henforcer.Entity do

  import Helix.Henforcer

  alias Helix.Network.Query.Network, as: NetworkQuery
  alias Helix.Server.Model.Component
  alias Helix.Server.Model.Server
  alias Helix.Server.Henforcer.Component, as: ComponentHenforcer
  alias Helix.Server.Henforcer.Server, as: ServerHenforcer
  alias Helix.Server.Query.Component, as: ComponentQuery
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Query.Entity, as: EntityQuery

  @type entity_exists_relay :: %{entity: Entity.t}
  @type entity_exists_error ::
    {false, {:entity, :not_found}, entity_exists_relay}

  @spec entity_exists?(Entity.id) ::
    {true, entity_exists_relay}
    | entity_exists_error
  @doc """
  Henforces the given Entity exists.
  """
  def entity_exists?(entity_id = %Entity.ID{}) do
    with entity = %Entity{} <- EntityQuery.fetch(entity_id) do
      reply_ok(relay(%{entity: entity}))
    else
      _ ->
        reply_error({:entity, :not_found})
    end
  end

  @type owns_server_relay :: %{entity: Entity.t, server: Server.t}
  @type owns_server_relay_partial :: owns_server_relay
  @type owns_server_error ::
    {false, {:server, :not_belongs}, owns_server_relay_partial}
    | entity_exists_error
    | ServerHenforcer.server_exists_error

  @spec owns_server?(Entity.idt, Server.idt) ::
    {true, owns_server_relay}
    | owns_server_error
  @doc """
  Henforces the Entity is the owner of the given server.
  """
  def owns_server?(entity_id = %Entity.ID{}, server) do
    henforce entity_exists?(entity_id) do
      owns_server?(relay.entity, server)
    end
  end

  def owns_server?(entity, server_id = %Server.ID{}) do
    henforce(ServerHenforcer.server_exists?(server_id)) do
      owns_server?(entity, relay.server)
    end
  end

  def owns_server?(entity = %Entity{}, server = %Server{}) do
    with \
      owner = %Entity{} <- EntityQuery.fetch_by_server(server),
      true <- owner == entity
    do
      reply_ok()
    else
      _ ->
        reply_error({:server, :not_belongs})
    end
    |> wrap_relay(%{entity: entity, server: server})
  end

  def owns_component?(entity_id = %Entity.ID{}, component, owned) do
    henforce entity_exists?(entity_id) do
      owns_component?(relay.entity, component, owned)
    end
  end

  def owns_component?(entity, component_id = %Component.ID{}, owned) do
    henforce(ComponentHenforcer.component_exists?(component_id)) do
      owns_component?(entity, relay.component, owned)
    end
  end

  def owns_component?(entity = %Entity{}, component = %Component{}, nil) do
    owned_components =
      entity
      |> EntityQuery.get_components()
      |> Enum.map(&(ComponentQuery.fetch(&1.component_id)))

    owns_component?(entity, component, owned_components)
  end

  def owns_component?(entity = %Entity{}, component = %Component{}, owned) do
    if component in owned do
      reply_ok()
    else
      reply_error({:component, :not_belongs})
    end
    |> wrap_relay(
      %{entity: entity, component: component, owned_components: owned}
    )
  end

  def owns_nip?(entity_id = %Entity.ID{}, network_id, ip, owned) do
    henforce entity_exists?(entity_id) do
      owns_nip?(relay.entity, network_id, ip, owned)
    end
  end

  def owns_nip?(entity = %Entity{}, network_id, ip, nil) do
    owned_nips = NetworkQuery.Connection.get_by_entity(entity.entity_id)

    owns_nip?(entity, network_id, ip, owned_nips)
  end

  def owns_nip?(entity = %Entity{}, network_id, ip, owned) do
    nc = Enum.find(owned, &(&1.network_id == network_id and &1.ip == ip))

    if nc do
      reply_ok(%{network_connection: nc})
    else
      reply_error({:network_connection, :not_belongs})
    end
    |> wrap_relay(%{entity_network_connections: owned})
  end
end
