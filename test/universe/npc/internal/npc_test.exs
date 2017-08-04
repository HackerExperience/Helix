defmodule Helix.Universe.NPC.Internal.NPCTest do

  use Helix.Test.IntegrationCase

  alias HELL.TestHelper.Random
  alias Helix.Universe.NPC.Internal.NPC, as: NPCInternal
  alias Helix.Universe.NPC.Model.NPC

  test "creation" do
    npc = %NPC{npc_type: :download_center}
    assert {:ok, _} = NPCInternal.create(npc)
  end

  describe "fetching" do
    test "success by id" do
      {:ok, npc} = NPCInternal.create(%{})
      assert %NPC{} = NPCInternal.fetch(npc.npc_id)
    end

    test "fails when npc with id doesn't exist" do
      bogus = Random.pk()
      refute NPCInternal.fetch(bogus)
    end
  end

  test "deleting is idempotent" do
    {:ok, npc} = NPCInternal.create(%{})
    NPCInternal.delete(npc.npc_id)
    NPCInternal.delete(npc.npc_id)
    refute NPCInternal.fetch(npc.npc_id)
  end
end
