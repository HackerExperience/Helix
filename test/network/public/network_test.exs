defmodule Helix.Network.Public.NetworkTest do

  use Helix.Test.Case.Integration

  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Network.Public.Network, as: NetworkPublic

  alias HELL.TestHelper.Random
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Universe.NPC.Helper, as: NPCHelper
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Network.Web.Setup, as: WebSetup

  @internet NetworkHelper.internet_id()

  describe "browse/3" do
    test "valid resolution of VPC IP" do
      {target_server, _} = ServerSetup.server()
      {gateway, _} = ServerSetup.server()

      target_ip = ServerQuery.get_ip(target_server.server_id, @internet)

      assert {:ok, result} = NetworkPublic.browse(@internet, target_ip, gateway)

      assert result.webserver == {:account, %{}}
      refute result.password
    end

    test "valid resolution of NPC IP" do
      {gateway, _} = ServerSetup.server()
      {dc, dc_ip} = NPCHelper.download_center()

      assert {:ok, result} = NetworkPublic.browse(@internet, dc_ip, gateway)

      assert result.webserver == {:npc, WebSetup.npc(dc.id, dc_ip)}
      refute result.password
    end

    test "returns web_not_found error when IP doesnt exists" do
      {gateway, _} = ServerSetup.server()

      assert {:error, error_msg} =
        NetworkPublic.browse(@internet, Random.ipv4(), gateway)

      assert error_msg == %{message: "web_not_found"}
    end
  end
end
