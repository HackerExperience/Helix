defmodule Helix.Server.Websocket.Channel.Server.Requests.NetworkTest do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest
  import Helix.Test.Macros

  alias HELL.TestHelper.Random
  alias Helix.Test.Cache.Helper, as: CacheHelper
  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Software.Setup, as: SoftwareSetup
  alias Helix.Test.Universe.NPC.Helper, as: NPCHelper
  alias Helix.Test.Server.Helper, as: ServerHelper
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
      assert_reply ref, :ok, response, timeout()

      # It contains the web server content
      assert response.data.content
      assert response.data.content.title

      # It contains metadata about the server type (and subtype if applicable)
      # In this case, since it's an NPC, the string must start with `npc_`
      # Example: `npc_download_center` or `npc_bank`
      assert String.starts_with?(response.data.type, "npc_")

      # It returns the target nip
      assert response.data.meta.nip ==
        [to_string(@internet_str), to_string(npc_ip)]

      # And the Database password info (in this case it's empty)
      refute response.data.meta.password

      CacheHelper.sync_test()
    end

    # Context: If player A is connected to B, and makes a `browse`
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
      assert_reply ref, :ok, response, timeout()

      # Resolved correctly
      assert response.data.content
      assert response.data.content.title
      assert response.data.meta.nip ==
        [to_string(@internet_str), to_string(npc_ip)]

      # No password
      refute response.data.meta.password

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
      assert_reply ref, :ok, response, timeout()

      # Resolved correctly
      assert response.data.content
      assert response.data.content.title
      assert response.data.meta.nip ==
        [to_string(@internet_str), to_string(npc_ip)]

      # No password
      refute response.data.meta.password

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
      assert_reply ref, :error, response, timeout(:fast)
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
      assert_reply ref, :error, response, timeout(:fast)
      assert response.data.message == "web_not_found"

      CacheHelper.sync_test()
    end

    test "resolution returns list of PublicFTP files" do
      {socket, _} = ChannelSetup.join_server([own_server: true])
      {target, _} = ServerSetup.server()

      # Let's enable the PFTP server on the target...
      SoftwareSetup.PFTP.pftp(server_id: target.server_id)

      # And add 3 files into it.
      SoftwareSetup.PFTP.file(server_id: target.server_id)
      SoftwareSetup.PFTP.file(server_id: target.server_id)
      SoftwareSetup.PFTP.file(server_id: target.server_id)

      target_ip = ServerHelper.get_ip(target)

      params = %{
        address: target_ip,
        network_id: @internet_str
      }

      # Browse to the NPC ip
      ref = push socket, "network.browse", params

      # Make sure the answer is an astounding :ok
      assert_reply ref, :ok, response, timeout()

      pftp_files = response.data.meta.public

      assert length(pftp_files) == 3
    end

    @tag :pending
    test "resolution returning password"

    @tag :pending
    test "resolution of VPC server"
  end
end
