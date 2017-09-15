defmodule Helix.Server.Websocket.Channel.Server.Requests.BrowseTest do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest

  alias HELL.TestHelper.Random
  alias Helix.Test.Cache.Helper, as: CacheHelper
  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Universe.NPC.Helper, as: NPCHelper
  alias Helix.Test.Server.Setup, as: ServerSetup

  @internet_str to_string(NetworkHelper.internet_id())

  describe "network.browse" do
    test "valid resolution, originating from my own server" do
      {socket, _} = ChannelSetup.join_server([own_server: true])
      {_, npc_ip} = NPCHelper.random()

      params = %{
        address: npc_ip,
        network_id: @internet_str
      }

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

      params = %{
        address: npc_ip,
        network_id: @internet_str
      }

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

      params = %{
        address: npc_ip,
        origin: gateway.server_id,
        network_id: @internet_str
      }

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

      params = %{
        address: npc_ip,
        origin: ServerSetup.id(),
        network_id: @internet_str
      }

      # Browse to the NPC ip asking random server to be used as origin
      ref = push socket, "network.browse", params

      # It return an error!
      assert_reply ref, :error, response
      assert response.data.message == "bad_origin"

      CacheHelper.sync_test()
    end

    test "not found resolution" do
      {socket, _} = ChannelSetup.join_server([own_server: true])

      params = %{
        address: Random.ipv4(),
        network_id: @internet_str
      }

      # Browse to random IP
      ref = push socket, "network.browse", params

      # It return an error!
      assert_reply ref, :error, response
      assert response.data.message == "web_not_found"

      CacheHelper.sync_test()
    end
  end
end
