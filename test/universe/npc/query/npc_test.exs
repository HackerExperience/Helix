defmodule Helix.Universe.NPC.Query.NPCTest do

  use Helix.Test.IntegrationCase

  alias Helix.Entity.Model.Entity
  alias Helix.Universe.NPC.Model.NPC
  alias Helix.Universe.NPC.Query.NPC, as: NPCQuery
  alias Helix.Universe.NPC.Helper, as: NPCHelper

  describe "fetch/1" do
    test "with npc id" do
      npc = NPCHelper.random()
      assert NPCQuery.fetch(npc.id)
    end

    test "with entity id" do
      npc = NPCHelper.random()
      entity_id = Entity.ID.cast!(npc.id)
      assert NPCQuery.fetch(entity_id)
    end

    test "with non-existing id" do
      refute NPCQuery.fetch(NPC.ID.generate())
    end
  end
end
