defmodule Helix.Server.Websocket.Channel.ServerTest do

  use Helix.Test.IntegrationCase

  alias Helix.Websocket.Socket

  alias Helix.Server.Factory, as: ServerFactory
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

  # TODO: Move this to a factory
  defp create_server_for_account(account) do
    alias Helix.Entity.Factory, as: EntityFactory

    # FIXME PLEASE
    entity = EntityFactory.insert(:entity, entity_id: account.account_id)

    create_server_for_entity(entity)
  end

  defp create_destination_server do
    alias Helix.Entity.Factory, as: EntityFactory

    entity = EntityFactory.insert(:entity)

    create_server_for_entity(entity)
  end

  defp create_server_for_entity(entity) do
    alias Helix.Hardware.Factory, as: HardwareFactory
    alias Helix.Hardware.Service.API.Motherboard, as: MotherboardAPI
    alias Helix.Entity.Service.API.Entity, as: EntityAPI
    alias Helix.Server.Service.API.Server, as: ServerAPI
    alias Helix.Server.Factory, as: ServerFactory

    # FIXME PLEASE
    server = ServerFactory.insert(:server)
    EntityAPI.link_server(entity, server.server_id)

    # I BEG YOU, SAVE ME FROM THIS EXCRUCIATING PAIN
    motherboard = HardwareFactory.insert(:motherboard)
    Enum.each(motherboard.slots, fn slot ->
      component = HardwareFactory.insert(slot.link_component_type)
      component = component.component

      MotherboardAPI.link(slot, component)
    end)
    {:ok, server} = ServerAPI.attach(server, motherboard.motherboard_id)

    server
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

  defp connect_to_realword_server(socket) do
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

    %{
      socket: socket,
      gateway: gateway,
      destination: destination_id,
      files: destination_files
    }
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

  test "returns files on server", context do
    context = connect_to_realword_server(context.socket)

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
    @tag :pending
    test "fetches logs on the destination"
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
