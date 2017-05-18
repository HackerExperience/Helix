defmodule Helix.Server.Websocket.Channel.ServerTest do

  use Helix.Test.IntegrationCase

  alias Helix.Websocket.Socket

  alias Helix.Entity.Service.API.Entity, as: EntityAPI
  alias Helix.Log.Service.API.Log, as: LogAPI
  alias Helix.Network.Factory, as: NetworkFactory

  import Phoenix.ChannelTest

  @endpoint Helix.Endpoint

  # TODO: Move this to a case
  setup do
    alias Helix.Account.Factory
    alias Helix.Account.Service.API.Session

    account = Factory.insert(:account)
    token = Session.generate_token(account)
    {:ok, socket} = connect(Socket, %{token: token})

    {:ok, account: account, socket: socket}
  end

  # FIXME: This will certainly break in the worst way in the future, but right
  #   now it's good enough for me not to suffer
  defp create_server_for_account(account) do
    alias Helix.Account.Service.Flow.Account, as: AccountFlow

    {:ok, %{server: server}} = AccountFlow.setup_account(account)

    server
  end

  defp create_destination_server do
    alias Helix.Account.Factory, as: AccountFactory

    account = AccountFactory.insert(:account)

    create_server_for_account(account)
  end

  defp populate_server_with_files(server) do
    alias Helix.Software.Factory, as: SoftwareFactory
    alias Helix.Hardware.Service.API.Component, as: ComponentAPI
    alias Helix.Hardware.Service.API.Motherboard, as: MotherboardAPI

    hdds =
      server.motherboard_id
      |> ComponentAPI.fetch()
      |> MotherboardAPI.fetch!()
      |> MotherboardAPI.get_slots()
      |> Enum.filter(&(&1.link_component_type == :hdd))
      |> Enum.reject(&(is_nil(&1.link_component_id)))
      |> Enum.map(&(&1.link_component_id))

    Enum.flat_map(hdds, fn drive ->
      storage = SoftwareFactory.insert(:storage, drives: [])
      SoftwareFactory.insert(:storage_drive, storage: storage, drive_id: drive)

      storage.files
    end)
  end

  defp connect_to_realword_server(context = %{socket: socket}) do
    gateway = create_server_for_account(socket.assigns.account)
    gateway_id = gateway.server_id
    destination = create_destination_server()
    destination_files = populate_server_with_files(destination)
    destination_id = destination.server_id

    topic = "server:" <> destination_id
    join_msg = %{"gateway_id" => gateway_id}

    # TODO: Make this an integration factory function
    tunnel = NetworkFactory.insert(
      :tunnel,
      gateway_id: gateway_id,
      destination_id: destination_id)
    NetworkFactory.insert(:connection,
      tunnel: tunnel,
      connection_type: "ssh")

    {:ok, _, socket} = join(socket, topic, join_msg)

    data = %{
      socket: socket,
      gateway: gateway,
      destination: destination_id,
      files: destination_files
    }

    Map.merge(context, data)
  end

  test "can connect to owned server", context do
    server = create_server_for_account(context.account)
    assert {:ok, _, _} = join(context.socket, "server:" <> server.server_id)
  end

  test "can not connect to a non owned server without connection", context do
    server = create_destination_server()

    assert {:error, _} = join(context.socket, "server:" <> server.server_id)
  end

  test \
    "can connect to a destination if a suitable connection exists",
    context
  do
    gateway = create_server_for_account(context.account)
    gateway = gateway.server_id
    destination = create_destination_server()
    destination = destination.server_id

    topic = "server:" <> destination
    join_msg = %{"gateway_id" => gateway}

    # Fails because there is no connection between the two servers
    assert {:error, _} = join(context.socket, topic, join_msg)

    # TODO: Make this an integration factory function
    tunnel = NetworkFactory.insert(
      :tunnel,
      gateway_id: gateway,
      destination_id: destination)
    NetworkFactory.insert(:connection,
      tunnel: tunnel,
      connection_type: "ssh")

    # With a valid SSH connection, a join is possible
    assert {:ok, _, _} = join(context.socket, topic, join_msg)
  end

  test "can start connection with a server", context do
    gateway = create_server_for_account(context.account)
    gateway = gateway.server_id
    destination = create_destination_server()

    topic = "server:" <> destination.server_id
    join_msg = %{
      "gateway_id" => gateway,
      "network_id" => "::", # The hardcoded way is the right way (tm)
      "password" => destination.password
    }

    assert {:ok, _, _} = join(context.socket, topic, join_msg)

    # This will emit an event...
    :timer.sleep(250)
  end

  test "returns files on server", context do
    context = connect_to_realword_server(context)

    ref = push context.socket, "file.index", %{}

    assert_reply ref, :ok, file_map

    expected_file_ids =
      context.files
      |> Enum.map(&(&1.file_id))
      |> Enum.sort()
    file_ids =
      file_map
      |> Map.values()
      |> List.flatten()
      |> Enum.map(&(&1.file_id))
      |> Enum.sort()

    assert is_map(file_map)
    assert Enum.all?(Map.keys(file_map), &is_binary/1)
    assert expected_file_ids == file_ids
  end

  describe "process.index" do
    @tag :pending
    test "fetches all processes running on destination"

    @tag :pending
    test "fetches all processes targeting destination"
  end

  describe "log.index" do
    test "fetches logs on the destination", context do
      context = connect_to_realword_server(context)

      server_id = context.destination
      entity_id = EntityAPI.get_entity_id(context.account)

      LogAPI.create(server_id, entity_id, "foo")
      LogAPI.create(server_id, entity_id, "bar")
      LogAPI.create(server_id, entity_id, "baz")

      ref = push context.socket, "log.index", %{}

      assert_reply ref, :ok, response

      assert %{data: %{logs: logs}} = response
      assert [%{message: "baz"}, %{message: "bar"}, %{message: "foo"}] = logs
    end
  end

  describe "log.delete" do
    @tag :pending
    test "start a process to delete target log"

    @tag :pending
    test "fails if log does not belong to target server"
  end

  describe "file.download" do
    @tag :pending
    test "initiates a process to download the specified file"

    @tag :pending
    test "returns error if the file does not belongs to target server"
  end

  @tag :pending
  test "server is notified when a process is created"

  @tag :pending
  test "server is notified when a process is completed"

  @tag :pending
  test "server is notified when a log is created"

  @tag :pending
  test "server is notified when a log is modified"

  @tag :pending
  test "server is notified when a log is deleted"
end
