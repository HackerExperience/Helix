defmodule Helix.Universe.NPC.Query.NPCTest do

  use Helix.Test.Case.Integration

  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Universe.NPC.Query.NPC, as: NPCQuery

  alias Helix.Test.Universe.NPC.Helper, as: NPCHelper

  describe "fetch/1" do
    test "with npc id" do
      {npc, _} = NPCHelper.random()
      assert NPCQuery.fetch(npc.id)
    end

    test "with entity id" do
      {npc, _} = NPCHelper.random()
      entity_id = EntityQuery.get_entity_id(npc.id)
      assert NPCQuery.fetch(entity_id)
    end

    test "with non-existing id" do
      refute NPCQuery.fetch(NPCHelper.id())
    end
  end
end
