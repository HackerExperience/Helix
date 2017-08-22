defmodule Helix.Test.Channel.Setup do

  import Phoenix.ChannelTest

  alias Helix.Websocket.Socket

  alias Helix.Test.Account.Setup, as: AccountSetup
  alias Helix.Test.Network.Setup, as: NetworkSetup
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
  - socket: Whether to reuse an existing socket.
  - own_server: Whether joining player's own server. No destination is created.
  - network_id: Specify network id. Not used if `own_server`
  - bounces: List of bounces between each server. Not used if `own_server`.
    Expected type: [Server.id]
  - gateway_files: Whether to generate random files on gateway. Defaults to
    false. TODO
  - destination_files: Whether to generate random files on destination. Defaults
    to false. TODO

  Related:
    Account.t, gateway :: Server.t, destination :: Server.t | nil, \
    destination_files :: [SoftwareSetup.file] | nil,
    gateway_files :: [SoftwareSetup.file] | nil,
  """
  def join_server(opts = [own_server: true]) do
    {socket, %{account: account, server: gateway}} = create_socket()

    gateway_id = to_string(gateway.server_id)

    topic = "server:" <> gateway_id
    join_params = %{
      "gateway_id" => gateway_id
    }

    gateway_files = generate_files(opts[:gateway_files], gateway.server_id)

    {:ok, _, socket} = join(socket, topic, join_params)

    related = %{
      account: account,
      gateway: gateway,
      gateway_files: gateway_files
    }

    {socket, related}
  end

  def join_server(opts \\ []) do
    {socket, %{account: account, server: gateway}} = create_socket()

    {destination, _} = ServerSetup.server()

    gateway_id = to_string(gateway.server_id)
    destination_id = to_string(destination.server_id)
    network_id = Access.get(opts, :network_id, "::")

    bounces = Access.get(opts, :bounces, [])
    bounces_string = Enum.map(bounces, fn server_id -> to_string(server_id) end)

    topic = "server:" <> destination_id
    join_params = %{
      "gateway_id" => gateway_id,
      "network_id" => network_id,
      "password" => destination.password,
      # bounces: bounces_string
    }

    gateway_files = generate_files(opts[:gateway_files], gateway.server_id)
    destination_files =
      generate_files(opts[:destination_files], destination.server_id)

    {:ok, _, socket} = join(socket, topic, join_params)

    related = %{
      account: account,
      gateway: gateway,
      destination: destination,
      destination_files: destination_files,
      gateway_files: gateway_files
    }

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
end
