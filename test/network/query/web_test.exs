defmodule Helix.Network.Query.WebTest do

  use Helix.Test.IntegrationCase

  alias HELL.TestHelper.Random
  alias Helix.Network.Query.Web, as: WebQuery
  alias Helix.Network.Helper, as: NetworkHelper
  alias Helix.Universe.NPC.Helper, as: NPCHelper

  describe "browse/3" do
    test "it browses with ip" do
      {_, ip} = NPCHelper.download_center()

      assert {:ok, resolution} =
        WebQuery.browse(NetworkHelper.internet_id, ip, Random.ipv4())
      assert {:npc, content} = resolution
      assert content.title
    end

    test "it browses with name" do
      {dc, _} = NPCHelper.download_center()

      assert {:ok, resolution} =
        WebQuery.browse(NetworkHelper.internet_id, dc.anycast, Random.ipv4())
      assert {:npc, content} = resolution
      assert content.title
    end

    test "it wont find non-existing ip" do
      assert {:error, :notfound} ==
        WebQuery.browse(NetworkHelper.internet_id, "1.3.3.7", Random.ipv4())
    end

    test "it wont find non-existing domain" do
      assert {:error, :nxdomain} ==
        WebQuery.browse(NetworkHelper.internet_id, "lol.com", Random.ipv4())
    end
  end

end
