defmodule Helix.Server.Henforcer.Channel do

  import Helix.Henforcer

  alias Helix.Entity.Model.Entity
  alias Helix.Server.Henforcer.Server, as: ServerHenforcer
  alias Helix.Server.Model.Server

  alias Helix.Entity.Henforcer.Entity, as: EntityHenforcer

  @type local_join_allowed_relay :: %{entity: Entity.t, server: Server.t}
  @type local_join_allowed_error ::
    EntityHenforcer.owns_server_error
    | ServerHenforcer.server_assembled_error

  @spec local_join_allowed?(Entity.id, Server.id) ::
    {true, local_join_allowed_relay}
    | local_join_allowed_error
  @doc """
  Henforces that `entity_id` can join `gateway_id` on a local connection.
  """
  def local_join_allowed?(entity_id, gateway_id) do
    with \
      {true, r1} <- EntityHenforcer.owns_server?(entity_id, gateway_id),
      server = r1.server,
      {true, r2} <- ServerHenforcer.server_assembled?(server)
    do
      reply_ok(relay(r1, r2))
    end
  end

  @type remote_join_allowed_relay ::
    %{entity: Entity.t, gateway: Server.t, destination: Server.t}
  @type remote_join_allowed_error ::
    EntityHenforcer.owns_server_error
    | ServerHenforcer.server_assembled_error
    | ServerHenforcer.password_valid_error

  @spec remote_join_allowed?(Entity.id, Server.id, Server.id, Server.password) ::
    {true, remote_join_allowed_relay}
    | remote_join_allowed_error
  @doc """
  Henforces that `entity_id` can join `destination_id` with `password` on a
  remote connection originating from `gateway_id`.
  """
  def remote_join_allowed?(entity_id, gateway_id, destination_id, password) do
    with \
      {true, r1} <- EntityHenforcer.owns_server?(entity_id, gateway_id),
      {r1, gateway} = get_and_replace(r1, :server, :gateway),
      {true, _} <- ServerHenforcer.server_assembled?(gateway),
      {true, r2} <- ServerHenforcer.server_assembled?(destination_id),
      {r2, destination} <- get_and_replace(r2, :server, :destination),
      {true, _} <- ServerHenforcer.password_valid?(destination, password)
    do
      reply_ok(relay(r1, r2))
    end
  end
end
