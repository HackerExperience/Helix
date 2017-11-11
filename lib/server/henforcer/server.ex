defmodule Helix.Server.Henforcer.Server do

  import Helix.Henforcer

  alias Helix.Core.Validator
  alias Helix.Entity.Henforcer.Entity, as: EntityHenforcer
  alias Helix.Entity.Model.Entity
  alias Helix.Server.Model.Server
  alias Helix.Server.Query.Server, as: ServerQuery

  @type server_exists_relay :: %{server: Server.t}
  @type server_exists_relay_partial :: %{}
  @type server_exists_error ::
    {false, {:server, :not_found}, server_exists_relay_partial}

  @spec server_exists?(Server.idt) ::
    {true, server_exists_relay}
    | server_exists_error
  @doc """
  Ensures the requested server exists on the database.
  """
  def server_exists?(server = %Server{}),
    do: server_exists?(server.server_id)
  def server_exists?(server_id = %Server.ID{}) do
    with server = %Server{} <- ServerQuery.fetch(server_id) do
      reply_ok(%{server: server})
    else
      _ ->
        reply_error({:server, :not_found})
    end
  end

  @type server_assembled_relay :: server_exists_relay
  @type server_assembled_relay_partial :: server_exists_relay
  @type server_assembled_error ::
    {false, {:server, :not_assembled}, server_assembled_relay_partial}
    | server_exists_error

  @spec server_assembled?(Server.idt) ::
    {true, server_assembled_relay}
    | server_assembled_error
  @doc """
  Henforces the server has a valid motherboard attached to it.
  """
  def server_assembled?(server_id = %Server.ID{}) do
    henforce(server_exists?(server_id)) do
      server_assembled?(relay.server)
    end
  end

  def server_assembled?(server = %Server{}) do
    case server.motherboard_id do
      %{} ->
        reply_ok()
      nil ->
        reply_error({:server, :not_assembled})
    end
    |> wrap_relay(%{server: server})
  end

  @type password_valid_relay :: server_exists_relay
  @type password_valid_relay_partial :: server_exists_relay
  @type password_valid_error ::
    {false, {:password, :invalid}, password_valid_relay_partial}
    | server_exists_error

  @spec password_valid?(Server.idt, Server.password) ::
    {true, password_valid_relay}
    | password_valid_error
  @doc """
  Henforces the given password matches the one on the server.
  """
  def password_valid?(server_id = %Server.ID{}, password) do
    henforce(server_exists?(server_id)) do
      password_valid?(relay.server, password)
    end
  end

  def password_valid?(server = %Server{}, password) do
    if password == server.password do
      reply_ok()
    else
      reply_error({:password, :invalid})
    end
    |> wrap_relay(%{server: server})
  end

  @type hostname_valid_relay :: %{hostname: Server.hostname}
  @type hostname_valid_relay_partial :: %{}
  @type hostname_valid_error ::
    {false, {:hostname, :invalid}, hostname_valid_relay_partial}

  @spec hostname_valid?(Server.hostname) ::
    {true, hostname_valid_relay}
    | hostname_valid_error
  @doc """
  Henforces the given `hostname` is within the expected format, as set forth by
  the Validator.
  """
  def hostname_valid?(hostname) do
    case Validator.validate_input(hostname, :hostname) do
      {:ok, _} ->
        reply_ok(%{hostname: hostname})

      :error ->
        reply_error({:hostname, :invalid})
    end
  end

  @type can_set_hostname_relay ::
    %{entity: Entity.t, server: Server.t, hostname: Server.hostname}
  @type can_set_hostname_partial ::
    EntityHenforcer.owns_server_relay_partial
    | hostname_valid_relay_partial
  @type can_set_hostname_error ::
    hostname_valid_error
    | EntityHenforcer.owns_server_error

  @spec can_set_hostname?(Entity.id, Server.id, Server.hostname) ::
    {true, can_set_hostname_relay}
    | can_set_hostname_error
  @doc """
  Henforces the `entity` can modify the `server` with such `hostname`
  """
  def can_set_hostname?(entity_id, server_id, hostname) do
    with \
      {true, r1} <- EntityHenforcer.owns_server?(entity_id, server_id),
      # Ensure the entity owns the server

      # Ensure the given hostname is valid
      {true, r2} <- hostname_valid?(hostname)
    do
      reply_ok(relay(r1, r2))
    else
      error ->
        error
    end
  end
end
