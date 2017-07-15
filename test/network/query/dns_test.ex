defmodule Helix.Network.Query.DNSTest do

  use Helix.Test.IntegrationCase

  alias HELL.IPv4
  alias Helix.Entity.Model.EntityType
  alias Helix.Universe.NPC.Model.Seed
  alias Helix.Universe.NPC.Query.NPC, as: NPCQuery
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias HELL.TestHelper.Random
  alias Helix.Network.Internal.Web.NPC, as: WebNPCInternal
  alias Helix.Network.Internal.Web, as: WebInternal
  alias Helix.Network.Query.DNS, as: DNSQuery
  alias Helix.Network.Repo

  setup do
    alias Helix.Account.Factory, as: AccountFactory
    alias Helix.Account.Action.Flow.Account, as: AccountFlow

    account = AccountFactory.insert(:account)
    {:ok, %{server: server}} = AccountFlow.setup_account(account)

    {:ok, account: account, server: server}
  end

  describe "resolve/2" do
    test "NPC resolution" do
      dc = Seed.search_by_type(:download_center)
      dc_domain = dc.anycast
      dc_ip = dc.servers
      |> List.first()
      |> Map.get(:static_ip)

      {:ok, ip} = DNSQuery.resolve(dc_domain, IPv4.autogenerate())

      assert ip == dc_ip
    end

    test "won't resolve non-existing sites" do
      :nxdomain = DNSQuery.resolve("wwwwwwwww.jodi.org", IPv4.autogenerate())
    end
  end
end
