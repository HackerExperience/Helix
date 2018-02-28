defmodule Helix.Maroto.Functions do

  use Helix.Maroto.Aliases

  @internet_id NetworkHelper.internet_id()
  @relay nil

  defmacro __using__(_) do
    quote do

      import Helix.Maroto.Functions
      import Helix.Maroto.ClientTools

    end
  end

  @doc """
  Creates a player account, as well as the underlying Freeplay and Story servers

  Opts:
  - email: Set email. Defaults to random email
  - user: Set username. Defaults to random username
  - pass: Set password. Defaults to random password
  """
  def create_account(opts \\ []) do
    email = Keyword.get(opts, :email, Random.email())
    user = Keyword.get(opts, :user, Random.username())
    pass = Keyword.get(opts, :pass, Random.string(min: 8, max: 10))

    related = %{email: email, user: user, pass: pass}

    {:ok, account} = AccountFlow.create(email, user, pass)

    {account, related}
  end

  @doc """
  Adds a new Database entry on `entity` corresponding to `server`

  Opts:
  - set_password: Whether the server password should be saved. Defaults to true.
  - network_id: Which network to set as origin. Defaults to @internet_id
  """
  def database_server_add(entity, server, opts \\ [])

  def database_server_add(entity, server_id = %Server.ID{}, opts) do
    server = ServerQuery.fetch(server_id)

    database_server_add(entity, server, opts)
  end

  def database_server_add(entity, server = %Server{}, opts) do
    network_id = Keyword.get(opts, :network_id, @internet_id)
    set_password? = Keyword.get(opts, :set_password, true)

    ip = ServerHelper.get_ip(server, network_id)

    {:ok, _} = DatabaseAction.add_server(entity, network_id, ip, server)

    if set_password? do
      {:ok, _} =
        DatabaseAction.update_server_password(
          entity, network_id, ip, server.server_id, server.password
        )
    end

    :ok
  end

  @doc """
  Creates a connection of `type` from `gateway` to `target`.

  Opts:
  - network_id: What network should be used. Defaults to @internet.
  - bounce_id: What bounce id should be used. Defaults to nil (no bounce)
  - meta: What is the connection meta. Defaults to empty map.
  """
  def connection_add(gateway, target, type, opts \\ [])

  def connection_add(from = %Server{}, to, type, opts),
    do: connection_add(from.server_id, to, type, opts)
  def connection_add(from, to = %Server{}, type, opts),
    do: connection_add(from, to.server_id, type, opts)

  def connection_add(
    from_id = %Server.ID{}, to_id = %Server.ID{}, type, opts)
  do
    network_id = Keyword.get(opts, :network_id, @internet_id)
    bounce_id = Keyword.get(opts, :bounce_id, nil)
    meta = Keyword.get(opts, :meta, %{})

    info = {type, meta}

    {:ok, tunnel, connection} =
      TunnelFlow.connect(network_id, from_id, to_id, bounce_id, info, @relay)

    {:ok, tunnel, connection}
  end
end
