defmodule Helix.Universe.NPC.Seed.SeedTest do

  use Helix.Test.IntegrationCase

  import Helix.Test.IDCase

  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Entity.Internal.Entity, as: EntityInternal
  alias Helix.Hardware.Internal.NetworkConnection, as: NetworkConnectionInternal
  alias Helix.Network.Internal.DNS, as: DNSInternal
  alias Helix.Server.Internal.Server, as: ServerInternal
  alias Helix.Universe.NPC.Helper, as: NPCHelper
  alias Helix.Universe.NPC.Internal.NPC, as: NPCInternal
  alias Helix.Universe.NPC.Model.Seed
  alias Helix.Universe.NPC.Seed, as: NPCSeed

  describe "seed data" do
    test "it exists by default" do
      # If failing here, make sure you ran the migration. Try mix test.full
      npc = Seed.search_by_type(:download_center)
      assert NPCInternal.fetch(npc.id)
    end

    test "NPCHelper prunes all data" do
      NPCHelper.empty_database()

      npc = Seed.search_by_type(:download_center)
      server = List.first(npc.servers)

      # Removes stuff
      refute NPCInternal.fetch(npc.id)
      refute ServerInternal.fetch(server.id)
      refute NetworkConnectionInternal.fetch_by_nip("::", server.static_ip)
    end
  end

  describe "seed population" do
    test "it populates" do
      # Ensure database is clean
      NPCHelper.empty_database()

      # Populate
      NPCSeed.migrate()

      # Iterate & verify
      npcs = Seed.seed()
      Enum.map(npcs, fn(entry) ->

        npc = NPCInternal.fetch(entry.id)
        assert npc
        assert_id npc.npc_id, entry.id

        entity = EntityInternal.fetch(entry.id)
        assert npc
        assert_id entity.entity_id, entry.id

        Enum.map(entry.servers, fn(cur) ->
          server = ServerInternal.fetch(cur.id)
          assert server
          assert_id server.server_id, cur.id

          if cur.static_ip do
            assert {:ok, nips} = CacheQuery.from_server_get_nips(server)
            assert Enum.find(nips, &(&1.ip == cur.static_ip))
          end
        end)

        if entry.anycast do
          anycast = DNSInternal.lookup_anycast(entry.anycast)

          assert anycast
          assert anycast.name == entry.anycast
          assert_id anycast.npc_id, entry.id
        end
      end)
    end
  end
end
