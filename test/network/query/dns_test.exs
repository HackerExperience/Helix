defmodule Helix.Network.Query.DNSTest do

  use Helix.Test.IntegrationCase

  alias HELL.TestHelper.Random
  alias HELL.TestHelper.Setup
  alias Helix.Universe.NPC.Helper, as: NPCHelper
  alias Helix.Network.Action.DNS, as: DNSAction
  alias Helix.Network.Helper, as: NetworkHelper
  alias Helix.Network.Query.DNS, as: DNSQuery

  setup do
    {server, account} = Setup.server()
    {:ok, account: account, server: server}
  end

  describe "resolve/2" do
    test "NPC resolution (anycast)" do
      {dc, dc_ip} = NPCHelper.download_center()

      assert {:ok, ip} =
        DNSQuery.resolve(NetworkHelper.internet_id(), dc.anycast, Random.ipv4())

      assert ip == dc_ip
    end

    test "Unicast resolution" do
      site = "saocarlosagora.com.br"
      ip = Random.ipv4()

      {:ok, _} = DNSAction.register_unicast(NetworkHelper.internet_id, site, ip)
      assert {:ok, ip2} = DNSQuery.resolve(NetworkHelper.internet_id, site, ip)
      assert ip2 == ip
    end

    test "won't resolve non-existing sites" do
      assert {:error, reason} =
        DNSQuery.resolve(
          NetworkHelper.internet_id,
          "wwwwwwwww.jodi.org",
          Random.ipv4())
      assert reason == {:domain, :notfound}
    end
  end
end
