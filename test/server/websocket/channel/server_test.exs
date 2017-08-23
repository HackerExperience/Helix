defmodule Helix.Server.Websocket.Channel.ServerTest do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest
  import Helix.Test.Case.ID

  alias Helix.Entity.Query.Entity, as: EntityQuery

  alias HELL.TestHelper.Random
  alias Helix.Test.Cache.Helper, as: CacheHelper
  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Log.Helper, as: LogHelper
  alias Helix.Test.Log.Setup, as: LogSetup
  alias Helix.Test.Universe.NPC.Helper, as: NPCHelper
  alias Helix.Test.Server.Setup, as: ServerSetup

  @moduletag :driver

  test "can connect to owned server with simple join message" do
    {socket, %{server: gateway, account: account}} =
      ChannelSetup.create_socket()

    gateway_id = to_string(gateway.server_id)
    topic = "server:" <> gateway_id

    assert {:ok, _, new_socket} =
      join(socket, topic, %{"gateway_id" => gateway_id})

    assert new_socket.assigns.access_type == :local
    assert new_socket.assigns.account == account
    assert new_socket.assigns.servers.destination_id == gateway.server_id
    assert new_socket.assigns.servers.gateway_id == gateway.server_id
    assert new_socket.joined
    assert new_socket.topic == topic

    CacheHelper.sync_test()
  end

  test "can not connect to a remote server without valid password" do
    {socket, %{server: gateway}} = ChannelSetup.create_socket()
    {destination, _} = ServerSetup.server()

    gateway_id = to_string(gateway.server_id)
    destination_id = to_string(destination.server_id)

    assert {:error, _} = join(
      socket,
      "server:" <> destination_id,
      %{"gateway_id" => gateway_id,
        "network_id" => "::",
        "password" => "wrongpass"})

    CacheHelper.sync_test()
  end

  test "can start connection with a remote server" do
    {socket, %{server: gateway, account: account}} =
      ChannelSetup.create_socket()
    {destination, _} = ServerSetup.server()

    gateway_id = to_string(gateway.server_id)
    destination_id = to_string(destination.server_id)
    network_id = "::"

    topic = "server:" <> destination_id
    join_msg = %{
      "gateway_id" => gateway_id,
      "network_id" => network_id,
      "password" => destination.password
    }

    assert {:ok, _, new_socket} = join(socket, topic, join_msg)

    assert new_socket.assigns.access_type == :remote
    assert new_socket.assigns.account == account
    assert_id new_socket.assigns.network_id, network_id
    assert_id new_socket.assigns.servers.destination_id, destination.server_id
    assert_id new_socket.assigns.servers.gateway_id, gateway.server_id
    assert new_socket.joined
    assert new_socket.topic == topic

    CacheHelper.sync_test()
  end

  @tag :slow
  test "returns files on server" do
    {socket, %{destination_files: files}} =
      ChannelSetup.join_server([destination_files: true])

    ref = push socket, "file.index", %{}

    assert_reply ref, :ok, response
    file_map = response.data.files

    expected_file_ids =
      files
      |> Enum.map(&(&1.file_id))
      |> Enum.sort()

    returned_file_ids =
      file_map
      |> Map.values()
      |> List.flatten()
      |> Enum.map(&(&1.file_id))
      |> Enum.sort()

    assert is_map(file_map)
    assert Enum.all?(Map.keys(file_map), &is_binary/1)
    assert expected_file_ids == returned_file_ids

    CacheHelper.sync_test()
  end

  describe "process.index" do
    @tag :pending
    test "fetches all processes running on destination"

    @tag :pending
    test "fetches all processes targeting destination"
  end

  describe "log.index" do
    @tag :slow
    test "fetches logs on the destination" do
      {socket, %{account: account, destination: destination}} =
        ChannelSetup.join_server()

      server_id = destination.server_id
      entity_id = EntityQuery.get_entity_id(account)

      # Create some dummy logs
      log1 = LogSetup.log!([server_id: server_id, entity_id: entity_id])
      log2 = LogSetup.log!([server_id: server_id, entity_id: entity_id])
      log3 = LogSetup.log!([server_id: server_id, entity_id: entity_id])

      # Request logs
      ref = push socket, "log.index", %{}

      # Got a valid response...
      assert_reply ref, :ok, response
      assert %{data: %{logs: logs}} = response

      # Welp, when you connect to a server it emits an event that causes a log
      # to be created on the target server. We are ignoring those logs for this
      # test because yes
      logs = Enum.reject(logs, &(&1.message =~ "logged in as root"))

      # Ensure all logs have been returned
      assert logs == LogHelper.public_view([log3, log2, log1])

      CacheHelper.sync_test()
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

  describe "network.browse" do
    test "valid resolution, originating from my own server" do
      {socket, _} = ChannelSetup.join_server([own_server: true])
      {_, npc_ip} = NPCHelper.random()

      params = %{address: npc_ip}

      # Browse to the NPC ip
      ref = push socket, "network.browse", params

      # Make sure the answer is an astounding :ok
      assert_reply ref, :ok, response

      # It contains the web server content
      assert {:npc, web_content} = response.data.webserver
      assert web_content.title

      # And the Database password info (in this case it's empty)
      refute response.data.password

      CacheHelper.sync_test()
    end

    # Context: If player A is connected to B, and makes a `network.browse`
    # request within the B channel, the source of the request must be server B.
    test "valid resolution, made by player on a remote server" do
      {socket, _} = ChannelSetup.join_server()
      {_, npc_ip} = NPCHelper.random()

      params = %{address: npc_ip}

      # Browse to the NPC ip
      ref = push socket, "network.browse", params

      # It worked!
      assert_reply ref, :ok, response

      assert {:npc, web_content} = response.data.webserver
      assert web_content.title
      refute response.data.password

      # TODO: Once Anycast is implemented, use it to determine whether the
      # correct servers were in fact used for resolution

      CacheHelper.sync_test()
    end

    test "valid resolution, made on remote server with origin headers" do
      {socket, %{gateway: gateway}} = ChannelSetup.join_server()
      {_, npc_ip} = NPCHelper.random()

      params = %{address: npc_ip, origin: gateway.server_id}

      # Browse to the NPC ip asking `gateway` to be used as origin
      ref = push socket, "network.browse", params

      # It worked!
      assert_reply ref, :ok, response

      assert {:npc, web_content} = response.data.webserver
      assert web_content.title
      refute response.data.password

      # TODO: Once Anycast is implemented, use it to determine whether the
      # correct servers were in fact used for resolution

      CacheHelper.sync_test()
    end

    test "valid resolution but with invalid `origin` header" do
      {socket, _} = ChannelSetup.join_server()
      {_, npc_ip} = NPCHelper.random()

      params = %{address: npc_ip, origin: ServerSetup.id()}

      # Browse to the NPC ip asking `gateway` to be used as origin
      ref = push socket, "network.browse", params

      # It return an error!
      assert_reply ref, :error, response
      assert response.data.message == "bad_origin"

      CacheHelper.sync_test()
    end

    test "not found resolution" do
      {socket, _} = ChannelSetup.join_server([own_server: true])

      params = %{address: Random.ipv4()}

      # Browse to the NPC ip asking `gateway` to be used as origin
      ref = push socket, "network.browse", params

      # It return an error!
      assert_reply ref, :error, response
      assert response.data.message == "web_not_found"

      CacheHelper.sync_test()
    end
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
