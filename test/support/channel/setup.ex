defmodule Helix.Test.Channel.Setup do

  import Phoenix.ChannelTest

  alias Helix.Websocket.Socket
  alias Helix.Account.Websocket.Channel.Account, as: AccountChannel
  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Server.Websocket.Channel.Server, as: ServerChannel

  alias Helix.Test.Account.Setup, as: AccountSetup
  alias Helix.Test.Cache.Helper, as: CacheHelper
  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  @endpoint Helix.Endpoint

  @doc """
  - account: Specify which account to generate the socket to
  - with_server: Whether to generate an account with server. Defaults to true.

  Related: Account.t, Server.t (when `with_server` is true)
  """
  def create_socket(opts \\ [with_server: true]) do
    {account, related} =
      cond do
        opts[:with_server] ->
          AccountSetup.account([with_server: true])
        opts[:account] ->
          {opts[:account], %{}}
        true ->
          AccountSetup.account()
      end

    {token, _} = AccountSetup.token([account: account])
    {:ok, socket} = connect(Socket, %{token: token})

    {socket, Map.merge(%{account: account}, related)}
  end

  @doc """
  - account_id: Specify channel to join. Creates a new account if none is set.
  - socket: Specify which socket to use. Generates a new one if not set.

  If `socket` is given, an `account_id` must be set as well. Same for the
  reverse case (if `account_id` is defined, a `socket` must be given.

  Related: Account.id
  """
  def join_account(opts \\ []) do
    acc_without_socket = not is_nil(opts[:account_id]) and is_nil(opts[:socket])
    socket_without_acc = is_nil(opts[:account_id]) and not is_nil(opts[:socket])

    if acc_without_socket or socket_without_acc do
      raise "You must specify both :account_id and :socket"
    end

    {socket, account_id} =
      if opts[:socket] do
        {opts[:socket], opts[:account_id]}
      else
        {socket, %{account: account}} = create_socket()

        {socket, account.account_id}
      end

    topic = "account:" <> to_string(account_id)

    {:ok, _, socket} = subscribe_and_join(socket, AccountChannel, topic, %{})

    related = %{
      account_id: account_id,
    }

    {socket, related}
  end

  @doc """
  - socket: Whether to reuse an existing socket.
  - own_server: Whether joining player's own server. No destination is created.
  - network_id: Specify network id. Not used if `own_server`
  - bounces: List of bounces between each server. Not used if `own_server`.
    Expected type: [Server.id] TODO
  - gateway_files: Whether to generate random files on gateway. Defaults to
    false.
  - destination_files: Whether to generate random files on destination. Defaults
    to false.

  Related:
    Account.t, gateway :: Server.t, destination :: Server.t | nil, \
    destination_files :: [SoftwareSetup.file] | nil, \
    gateway_files :: [SoftwareSetup.file] | nil,
  """
  def join_server(opts \\ [])
  def join_server(opts = [own_server: true]) do
    {socket, %{account: account, server: gateway}} = create_socket()

    gateway_id = to_string(gateway.server_id)

    topic = "server:" <> gateway_id
    join_params = %{
      "gateway_id" => gateway_id
    }

    gateway_files = generate_files(opts[:gateway_files], gateway.server_id)

    {:ok, _, socket} =
      subscribe_and_join(socket, ServerChannel, topic, join_params)

    related = %{
      account: account,
      gateway: gateway,
      gateway_files: gateway_files
    }

    CacheHelper.sync_test()

    {socket, related}
  end

  def join_server(opts) do
    {socket, %{account: account, server: gateway}} = create_socket()

    {destination, _} = ServerSetup.server()

    gateway_id = to_string(gateway.server_id)
    destination_id = to_string(destination.server_id)
    network_id = Access.get(opts, :network_id, "::")

    {:ok, [target_nip]} = CacheQuery.from_server_get_nips(destination.server_id)

    # bounces = Access.get(opts, :bounces, [])

    topic = "server:" <> destination_id
    join_params = %{
      "gateway_id" => gateway_id,
      "network_id" => network_id,
      "password" => destination.password,
      "ip" => target_nip.ip
      # bounces: bounces_string
    }

    gateway_files = generate_files(opts[:gateway_files], gateway.server_id)
    destination_files =
      generate_files(opts[:destination_files], destination.server_id)

    {:ok, _, socket} =
      subscribe_and_join(socket, ServerChannel, topic, join_params)

    related = %{
      account: account,
      gateway: gateway,
      destination: destination,
      destination_files: destination_files,
      gateway_files: gateway_files
    }

    CacheHelper.sync_test()

    {socket, related}
  end

  defp generate_files(condition, server_id) do
    if condition do
      file_opts = [file_opts: [server_id: server_id]]
      SoftwareSetup.random_files!(file_opts)
    else
      nil
    end
  end

  @doc """
  Opts:
  - gateway_id
  - gateway_entity_id
  - destination_id
  - destination_entity_id
  - access_type: Inferred if not set
  - own_server: Force socket to represent own server channel
  """
  def mock_server_socket(opts \\ []) do
    gateway_id = Access.get(opts, :gateway_id, ServerSetup.id())
    gateway_entity_id = Access.get(opts, :gateway_entity_id, EntitySetup.id())

    {destination_id, destination_entity_id} =
      if opts[:own_server] do
        {gateway_id, gateway_entity_id}
      else
        server_id = Access.get(opts, :destination_id, ServerSetup.id())
        entity_id = Access.get(opts, :destination_entity_id, EntitySetup.id())

        {server_id, entity_id}
      end

    access_type =
      cond do
        opts[:access_type] ->
          opts[:access_type]

        gateway_id == destination_id ->
          :local

        true ->
          :remote
      end

    assigns = %{
      gateway: %{
        server_id: gateway_id,
        entity_id: gateway_entity_id
      },
      destination: %{
        server_id: destination_id,
        entity_id: destination_entity_id
      },
      access_type: access_type
    }

    %{assigns: assigns}
  end
end
