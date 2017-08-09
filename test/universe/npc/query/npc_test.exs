defmodule Helix.Universe.NPC.Query.NPCTest do

  use Helix.Test.IntegrationCase

  alias HELL.TestHelper.Random
  alias Helix.Entity.Model.Entity
  alias Helix.Universe.NPC.Model.NPC
  alias Helix.Universe.NPC.Query.NPC, as: NPCQuery
  alias Helix.Universe.NPC.Helper, as: NPCHelper

  describe "fetch/1" do
    test "it fetches (npc id)" do
      npc = NPCHelper.random()
      assert NPCQuery.fetch(npc.id)
    end

    test "it fetches (entity id)" do
      npc = NPCHelper.random()
      entity_id = Entity.ID.cast!(npc.id)
      assert NPCQuery.fetch(entity_id)
    end

    test "it won't fetch stuff that does not exist" do
      refute NPCQuery.fetch(NPC.ID.cast!(Random.pk()))
    end
  end
end
