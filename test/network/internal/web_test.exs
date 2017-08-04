defmodule Helix.Network.Internal.WebTest do

  use Helix.Test.IntegrationCase

  alias Helix.Universe.NPC.Model.Seed
  alias Helix.Universe.NPC.Query.NPC, as: NPCQuery
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias HELL.TestHelper.Random
  alias Helix.Network.Internal.Web.NPC, as: WebNPCInternal
  alias Helix.Network.Internal.Web, as: WebInternal
  alias Helix.Network.Repo

  describe "serve/2" do
    test "serves NPC pages correctly" do
      seed = Seed.search_by_type(:download_center)

      npc = NPCQuery.fetch(seed.id)
      entity = EntityQuery.fetch(npc.npc_id)
      [server_id] = EntityQuery.get_servers(npc.npc_id)

      ip = ServerQuery.get_ip(server_id, "::")

      {:npc, page} = WebInternal.serve(ip, entity)

      refute page == :notfound
      assert page == %{a: "b"}

      :timer.sleep(10)
    end
  end
end
