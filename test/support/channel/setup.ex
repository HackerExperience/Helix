defmodule Helix.Test.Channel.Setup do

  import Phoenix.ChannelTest

  alias Helix.Websocket
  alias HELL.Utils
  alias Helix.Account.Model.Account
  alias Helix.Account.Query.Account, as: AccountQuery
  alias Helix.Account.Websocket.Channel.Account, as: AccountChannel
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Server
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Server.Websocket.Channel.Server, as: ServerChannel
  alias Helix.Story.Query.Manager, as: ManagerQuery

  alias HELL.TestHelper.Random
  alias Helix.Test.Account.Setup, as: AccountSetup
  alias Helix.Test.Cache.Helper, as: CacheHelper
  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Network.Setup, as: NetworkSetup
  alias Helix.Test.Network.Setup.Connection, as: ConnectionSetup
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Software.Setup, as: SoftwareSetup
  alias Helix.Test.Universe.Bank.Setup, as: BankSetup
  alias Helix.Test.Channel.Helper, as: ChannelHelper

  @endpoint Helix.Endpoint

  @internet_id NetworkHelper.internet_id()

  @doc """
  - account: Specify which account to generate the socket to
  - entity_id: Specify entity ID that socket should be generated to.
  - with_server: Whether to generate an account with server. Defaults to true.
  - client: Specify which `client` should be used. Defaults to "web2".

  Related: Account.t, Server.t (when `with_server` is true)
  """
  def create_socket(opts \\ []) do
    with_server? = Keyword.get(opts, :with_server, true)

    {account, related} =
      cond do
        with_server? ->
          AccountSetup.account(with_server: true)

        opts[:entity_id] ->
          account_id = Account.ID.cast!(to_string(opts[:entity_id]))
          account = AccountQuery.fetch(account_id)
          {account, %{}}

        opts[:account] ->
          {opts[:account], %{}}

        true ->
          AccountSetup.account()
      end

    client = Keyword.get(opts, :client, :web2) |> to_string()
    entity =
      account.account_id
      |> EntityQuery.get_entity_id()
      |> EntityQuery.fetch()

    {token, _} = AccountSetup.token([account: account])

    params =
      %{
        token: token,
        client: client
      }

    {:ok, socket} = connect(Websocket, params)

    related =
      related
      |> Map.merge(%{account: account})
      |> Map.merge(%{token: token})
      |> Map.merge(%{entity: entity})

    {socket, related}
  end

  @doc """
  - account_id: Specify channel to join. Creates a new account if none is set.
  - socket: Specify which socket to use. Generates a new one if not set.
  - socket_opts: Relays opts to the `create_socket/1` method (if applicable)

  If `socket` is given, an `account_id` must be set as well. Same for the
  reverse case (if `account_id` is defined, a `socket` must be given.

  Related: Account.id, Entity.id
  """
  def join_account(opts \\ []) do
    acc_without_socket = not is_nil(opts[:account_id]) and is_nil(opts[:socket])
    socket_without_acc = is_nil(opts[:account_id]) and not is_nil(opts[:socket])

    if acc_without_socket or socket_without_acc,
      do: raise "You must specify both :account_id and :socket"

    {socket, account_id, socket_related} =
      if opts[:socket] do
        {opts[:socket], opts[:account_id], %{}}
      else
        {socket, related} = create_socket(opts[:socket_opts] || [])

        {socket, related.account.account_id, related}
      end

    topic = "account:" <> to_string(account_id)

    {:ok, _, socket} = subscribe_and_join(socket, AccountChannel, topic, %{})

    related = %{
      account_id: account_id,
      entity_id: Entity.ID.cast!(to_string(account_id))
    }
    |> Map.merge(socket_related)

    {socket, related}
  end

  @doc """
  - socket: Whether to reuse an existing socket.
  - own_server: Whether joining player's own server. No destination is created.
  - gateway_id: Specify gateway server.
  - destination_id: Specify destination server.
  - network_id: Specify network id. Not used if `own_server`
  - counter: Specify counter (used by ServerWebsocketChannelState). Default is 0
  - bounce_id: Which bounce to use. Ignored if `own_server`.
  - gateway_files: Whether to generate random files on gateway. Defaults to
    false.
  - destination_files: Whether to generate random files on destination. Defaults
    to false.
  - socket_opts: Relays opts to the `create_socket/1` method (if applicable)

  Related:
    Account.t, \
    gateway :: Server.t, \
    gateway_entity :: Entity.t \
    gateway_files :: [SoftwareSetup.file] | nil, \
    gateway_ip :: Network.ip, \
    destination :: Server.t | nil, \
    destination_entity :: Entity.t | nil \
    destination_files :: [SoftwareSetup.file] | nil, \
    destination_ip :: Network.ip | nil
  """
  def join_server(opts \\ []) do
    {socket, %{account: account, server: gateway}} =
      cond do
        not is_nil(opts[:socket]) and not is_nil(opts[:gateway_id]) ->
          server = ServerQuery.fetch(opts[:gateway_id])
          {opts[:socket], %{account: nil, server: server}}

        opts[:socket] ->
          gateway =
            opts[:socket].assigns.gateway.server_id
            |> ServerQuery.fetch()

          {opts[:socket], %{account: nil, server: gateway}}

        true ->
          create_socket(opts[:socket_opts] || [])
      end

    local? = Keyword.get(opts, :own_server, false)

    {join, destination} =
      if local? do
        join = get_join_data(opts, gateway)

        {join, nil}
      else
        destination = ServerSetup.create_or_fetch(opts[:destination_id])

        join = get_join_data(opts, gateway, destination)

        {join, destination}
      end

    {:ok, _, socket} =
      subscribe_and_join(socket, ServerChannel, join.topic, join.params)

    gateway_files = generate_files(opts[:gateway_files], gateway.server_id)

    gateway_related = %{
      account: account,
      gateway: gateway,
      gateway_entity: EntityQuery.fetch(socket.assigns.gateway.entity_id),
      gateway_ip: join.gateway_ip,
      gateway_files: gateway_files,
    }

    destination_related =
      if local? do
        %{}
      else
        destination_files =
          generate_files(opts[:destination_files], destination.server_id)

        destination_entity =
          EntityQuery.fetch(socket.assigns.destination.entity_id)

        %{
          destination: destination,
          destination_entity: destination_entity,
          destination_ip: join.destination_ip,
          destination_files: destination_files
        }
      end

    related = Map.merge(gateway_related, destination_related)

    CacheHelper.sync_test()

    {socket, related}
  end

  defp get_join_data(opts, gateway = %Server{}, destination = %Server{}) do
    network_id = Keyword.get(opts, :network_id, @internet_id)
    bounce_id = Keyword.get(opts, :bounce_id, nil) |> Utils.stringify()

    gateway_ip = ServerQuery.get_ip(gateway.server_id, network_id)
    destination_ip = ServerQuery.get_ip(destination.server_id, network_id)

    counter =
      opts
      |> Keyword.get(:counter, 0)
      |> to_string()

    params =
      %{
        "gateway_ip" => gateway_ip,
        "password" => destination.password,
        "bounce_id" => bounce_id
       }

    topic = ChannelHelper.server_topic_name(network_id, destination_ip, counter)

    %{
      topic: topic,
      gateway_ip: gateway_ip,
      destination_ip: destination_ip,
      network_id: network_id,
      params: params
    }
  end

  defp get_join_data(_opts, gateway) do
    %{
      topic: ChannelHelper.server_topic_name(gateway.server_id),
      params: %{},
      gateway_ip: nil
    }
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
  - socket_opts: Opts to be relayed to `create_socket/1`
  """
  def join_storyline_server(opts \\ []) do
    {socket, %{account: account}} = create_socket(opts[:socket_opts] || [])

    manager = ManagerQuery.fetch(socket.assigns.entity_id)
    gateway = ServerQuery.fetch(manager.server_id)

    # Force `network_id` to be the Story network
    opts = Keyword.put(opts, :network_id, manager.network_id)

    join = get_join_data(opts, gateway)

    {:ok, _, socket} =
      subscribe_and_join(socket, ServerChannel, join.topic, join.params)

    files = generate_files(opts[:gateway_files], gateway.server_id)

    related = %{
      account: account,
      gateway: gateway,
      gateway_entity: EntityQuery.fetch(socket.assigns.entity_id),
      gateway_ip: join.gateway_ip,
      gateway_files: files,
      manager: manager
    }

    CacheHelper.sync_test()

    {socket, related}
  end

  @doc """
  Opts:
  - gateway_id
  - gateway_ip
  - gateway_entity_id
  - destination_id
  - destination_ip
  - destination_entity_id
  - network_id
  - access: Inferred if not set
  - own_server: Force socket to represent own server channel. Defaults to false.
  - counter: Defaults to 0.
  - connect_opts: Opts that will be relayed to the `mock_connection_socket`
  """
  def mock_server_socket(opts \\ []) do
    gateway_id = Access.get(opts, :gateway_id, ServerSetup.id())
    gateway_ip = Keyword.get(opts, :gateway_ip, Random.ipv4())
    gateway_entity_id = Access.get(opts, :gateway_entity_id, EntitySetup.id())

    {destination_id, destination_ip, destination_entity_id} =
      if opts[:own_server] do
        {gateway_id, gateway_ip, gateway_entity_id}
      else
        server_id = Access.get(opts, :destination_id, ServerSetup.id())
        server_ip = Keyword.get(opts, :server_ip, Random.ipv4())
        entity_id = Access.get(opts, :destination_entity_id, EntitySetup.id())

        {server_id, server_ip, entity_id}
      end

    access =
      cond do
        opts[:access] ->
          opts[:access]

        gateway_id == destination_id ->
          :local

        true ->
          :remote
      end

    network_id = Keyword.get(opts, :network_id, Network.ID.generate())
    counter = Keyword.get(opts, :counter, 0)
    meta = %{
      access: access,
      network_id: network_id,
      counter: counter
    }

    server_assigns = %{
      gateway: %{
        server_id: gateway_id,
        ip: gateway_ip,
        entity_id: gateway_entity_id
      },
      destination: %{
        server_id: destination_id,
        ip: destination_ip,
        entity_id: destination_entity_id
      },
      meta: meta
    }

    assigns =
      (opts[:connect_opts] || [])
      |> fake_connection_socket_assigns()
      |> Map.merge(server_assigns)

    %{
      assigns: assigns,
      joined: true
    }
  end

  @doc """
  Opts:
  - connect_opts: Opts that will be relayed to the `mock_connection_socket`
  """
  def mock_account_socket(opts \\ []) do
    acc_assigns = %{}

    assigns =
      (opts[:connect_opts] || [])
      |> fake_connection_socket_assigns()
      |> Map.merge(acc_assigns)

    %{
      assigns: assigns,
      joined: true
    }
  end

  def mock_bank_socket(opts \\ []) do
    gateway_id = Keyword.get(opts, :gateway_id, ServerSetup.id)
    gateway_entity_id = Keyword.get(opts, :gateway_entity_id, EntitySetup.id())

    account = BankSetup.account!()
    atm_id = Keyword.get(opts, :atm_id, account.atm_id)
    account_number = Keyword.get(opts, :account_number, account.account_number)

    account = AccountSetup.account!()
    account_id = account.account_id
    tunnel =
      NetworkSetup.tunnel!(
        gateway_id: gateway_id,
        target_id: atm_id
      )

    connection =
      ConnectionSetup.connection(
        entity_id: gateway_entity_id
      )

    gateway_data =
      %{
        server_id: gateway_id,
        entity_id: gateway_entity_id
      }

    assigns =
      %{
        atm_id: atm_id,
        account_number: account_number,
        account_id: account_id,
        gateway: gateway_data,
        tunnel: tunnel,
        bank_login: connection
      }

    assigns =
      (opts[:connect_opts] || [])
      |> fake_connection_socket_assigns()
      |> Map.merge(assigns)

    %{
      assigns: assigns,
      joined: true
    }
  end

  @doc """
  Opts:

  - entity_id: Set entity_id. Defaults to a random fake entity_id
  - account_id: Set account_id. Defaults to the corresponding Entity.ID
  - client: Set the client platform/version. Defaults to `web2`
  """
  def fake_connection_socket_assigns(opts \\ []) do
    gen_account_id = fn entity_id ->
      entity_id |> to_string() |> Account.ID.cast!()
    end

    entity_id = Keyword.get(opts, :entity_id, Entity.ID.generate())
    account_id = Keyword.get(opts, :account_id, gen_account_id.(entity_id))
    client = Keyword.get(opts, :client, :web2)

    %{
      entity_id: entity_id,
      account_id: account_id,
      client: client
    }
  end
end
