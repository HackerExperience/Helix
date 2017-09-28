defmodule Helix.Universe.NPC.Seed.SeedTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Case.ID

  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Entity.Internal.Entity, as: EntityInternal
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Hardware.Internal.NetworkConnection, as: NetworkConnectionInternal
  alias Helix.Network.Internal.DNS, as: DNSInternal
  alias Helix.Server.Internal.Server, as: ServerInternal
  alias Helix.Universe.Bank.Internal.ATM, as: ATMInternal
  alias Helix.Universe.Bank.Internal.Bank, as: BankInternal
  alias Helix.Test.Universe.NPC.Helper, as: NPCHelper
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

      {npc, _} = NPCHelper.random()
      server = List.first(npc.servers)
      {bank, _} = NPCHelper.bank()

      # Removes stuff
      refute NPCInternal.fetch(npc.id)
      refute ServerInternal.fetch(server.id)
      refute NetworkConnectionInternal.fetch_by_nip("::", server.static_ip)
      refute BankInternal.fetch(bank.id)
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
      Enum.each(npcs, fn(entry) ->

        npc = NPCInternal.fetch(entry.id)
        assert npc
        assert_id npc.npc_id, entry.id

        entity_id = EntityQuery.get_entity_id(entry.id)
        entity = EntityInternal.fetch(entity_id)
        assert npc
        assert_id entity.entity_id, entity_id

        Enum.each(entry.servers, fn(cur) ->
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

        test_specialization(entry, npc)
      end)
    end

    defp test_specialization(entry = %{type: :bank}, npc) do
      # Bank exists
      assert BankInternal.fetch(npc.npc_id)

      Enum.map(entry.servers, fn(atm) ->
        assert ATMInternal.fetch(atm.id)
      end)
    end
    defp test_specialization(%{custom: false}, _npc),
      do: :ok
    defp test_specialization(_, _),
      do: flunk "invalid specialization"
  end
end
