defmodule Helix.Server.Henforcer.Channel do

  import Helix.Henforcer

  alias Helix.Entity.Henforcer.Entity, as: EntityHenforcer
  alias Helix.Entity.Model.Entity
  alias Helix.Network.Model.Network
  alias Helix.Server.Henforcer.Server, as: ServerHenforcer
  alias Helix.Server.Model.Server
  alias Helix.Server.State.Websocket.Channel, as: ServerWebsocketChannelState

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
  def local_join_allowed?(entity_id, gateway_id = %Server.ID{}) do
    with \
      {true, r1} <- ServerHenforcer.server_exists?(gateway_id),
      gateway = r1.server,
      {true, r2} <- EntityHenforcer.owns_server?(entity_id, gateway),
      {true, _} <- ServerHenforcer.server_assembled?(gateway)
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

  @spec remote_join_allowed?(Entity.id, Server.t, Server.t, Server.password) ::
    {true, remote_join_allowed_relay}
    | remote_join_allowed_error
  @doc """
  Henforces that `entity_id` can join `destination_id` with `password` on a
  remote connection originating from `gateway_id`.
  """
  def remote_join_allowed?(
    entity_id = %Entity.ID{},
    gateway = %Server{},
    destination = %Server{},
    password)
  do
    with \
      {true, r1} <- EntityHenforcer.owns_server?(entity_id, gateway),
      r1 = drop(r1, :server),
      {true, _} <- ServerHenforcer.server_assembled?(gateway),
      {true, _} <- ServerHenforcer.server_assembled?(destination),
      {true, _} <- ServerHenforcer.password_valid?(destination, password)
    do
      reply_ok(r1)
    end
    |> wrap_relay(%{gateway: gateway, destination: destination})
  end

  @type valid_counter_relay :: %{counter: ServerWebsocketChannelState.counter}
  @type valid_counter_relay_partial :: %{}
  @type valid_counter_error ::
    {false, {:counter, :invalid}, valid_counter_relay_partial}

  @spec valid_counter?(
      Entity.id,
      Server.t,
      {Network.id, Network.ip},
      ServerWebsocketChannelState.counter | nil)
  ::
    {true, valid_counter_relay}
    | valid_counter_error
  def valid_counter?(entity_id, server = %Server{}, nip, nil) do
    next_counter =
      ServerWebsocketChannelState.get_next_counter(
        entity_id, server.server_id, nip
      )

     reply_ok(%{counter: next_counter})
  end
  def valid_counter?(entity_id, server = %Server{}, nip, counter) do
    valid? =
      ServerWebsocketChannelState.valid_counter?(
        entity_id, server.server_id, nip, counter
      )

    if valid? do
      reply_ok(%{counter: counter})
    else
      reply_error({:counter, :invalid})
    end
  end
end
