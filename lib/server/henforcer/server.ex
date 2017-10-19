defmodule Helix.Server.Henforcer.Server do

  import Helix.Henforcer

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
end
