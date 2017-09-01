defmodule Helix.Server.Websocket.Channel.Server.JoinTest do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest
  import Helix.Test.Case.ID

  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Server.Model.Server

  alias HELL.TestHelper.Random
  alias Helix.Test.Cache.Helper, as: CacheHelper
  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Server.Setup, as: ServerSetup

  @moduletag :driver

  setup_all do
    on_exit fn ->
      # Sleep for events
      :timer.sleep(100)
    end
  end

  test "can connect to owned server with simple join message" do
    {socket, %{server: gateway, account: account}} =
      ChannelSetup.create_socket()

    gateway_id = to_string(gateway.server_id)
    topic = "server:" <> gateway_id

    assert {:ok, _, new_socket} =
      join(socket, topic, %{"gateway_id" => gateway_id})

    assert new_socket.assigns.access_type == :local
    assert new_socket.assigns.account == account
    assert new_socket.assigns.gateway.server_id == gateway.server_id
    assert new_socket.assigns.destination.server_id == gateway.server_id
    assert new_socket.joined
    assert new_socket.topic == topic

    CacheHelper.sync_test()
  end

  test "can not connect locally to a server the player does not own" do
    {socket, _} =
      ChannelSetup.create_socket()

    random_server_id = to_string(Server.ID.generate())

    topic = "server:" <> random_server_id

    assert {:error, reason} =
      join(socket, topic, %{"gateway_id" => random_server_id})
    assert reason.data == "server_bad_owner"
  end

  test "can not connect to a remote server without valid password" do
    {socket, %{server: gateway}} = ChannelSetup.create_socket()
    {destination, _} = ServerSetup.server()

    {:ok, [target_nip]} = CacheQuery.from_server_get_nips(destination.server_id)

    topic = "server:" <> to_string(destination.server_id)

    params = %{
      "gateway_id" => to_string(gateway.server_id),
      "network_id" => to_string(target_nip.network_id),
      "ip" => target_nip.ip,
      "password" => "wrongpass"
    }

    assert {:error, reason} = join(socket, topic, params)
    assert reason.data == "server_bad_password"
  end

  test "can not connect to a remote server with an incorrect IP" do
    {socket, %{server: gateway}} =
      ChannelSetup.create_socket()
    {destination, _} = ServerSetup.server()

    gateway_id = to_string(gateway.server_id)
    destination_id = to_string(destination.server_id)
    network_id = "::"

    topic = "server:" <> destination_id
    join_msg = %{
      "gateway_id" => gateway_id,
      "network_id" => network_id,
      "password" => destination.password,
      "ip" => Random.ipv4()
    }

    assert {:error, reason} = join(socket, topic, join_msg)
    assert reason.data == "nip_not_found"
  end

  test "can not connect to a remote server with an invalid gateway" do
    {socket, _} =
      ChannelSetup.create_socket()
    {destination, _} = ServerSetup.server()

    random_server_id = to_string(Server.ID.generate())
    destination_id = to_string(destination.server_id)
    network_id = "::"

    {:ok, [target_nip]} = CacheQuery.from_server_get_nips(destination.server_id)

    topic = "server:" <> destination_id
    join_msg = %{
      "gateway_id" => random_server_id,
      "network_id" => network_id,
      "password" => destination.password,
      "ip" => target_nip.ip
    }

    assert {:error, reason} = join(socket, topic, join_msg)
    assert reason.data == "server_bad_owner"
  end

  test "can start connection with a remote server" do
    {socket, %{server: gateway, account: account}} =
      ChannelSetup.create_socket()
    {destination, _} = ServerSetup.server()

    gateway_id = to_string(gateway.server_id)
    destination_id = to_string(destination.server_id)
    network_id = "::"

    {:ok, [target_nip]} = CacheQuery.from_server_get_nips(destination.server_id)

    topic = "server:" <> destination_id
    join_msg = %{
      "gateway_id" => gateway_id,
      "network_id" => network_id,
      "password" => destination.password,
      "ip" => target_nip.ip
    }

    assert {:ok, _, new_socket} = join(socket, topic, join_msg)

    assert new_socket.assigns.access_type == :remote
    assert new_socket.assigns.account == account
    assert_id new_socket.assigns.network_id, network_id
    assert new_socket.assigns.gateway.server_id == gateway.server_id
    assert new_socket.assigns.destination.server_id == destination.server_id
    assert new_socket.joined
    assert new_socket.topic == topic

    # This might emit an event...
    :timer.sleep(250)
    CacheHelper.sync_test()
  end
end
