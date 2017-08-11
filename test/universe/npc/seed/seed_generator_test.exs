defmodule Helix.Universe.NPC.Seed.SeedGeneratorTest do

  use Helix.Test.IntegrationCase

  alias Helix.Universe.NPC.Model.Seed

  setup do
    {:ok, npcs: Seed.seed()}
  end

  describe "get_npc_id/1" do
    test "with existing data" do
      assert Seed.get_npc_id("DC0")
    end

    test "with non-existing data" do
      refute Seed.get_npc_id("AIJDFSAJDFI")
    end
  end
end
