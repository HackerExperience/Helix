defmodule Helix.Entity.Henforcer.Entity do

  import Helix.Henforcer

  alias Helix.Server.Model.Server
  alias Helix.Server.Henforcer.Server, as: ServerHenforcer
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
end
