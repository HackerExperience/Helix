defmodule Helix.NPC.Internal.NPCTest do

  use Helix.Test.IntegrationCase

  alias HELL.TestHelper.Random
  alias Helix.NPC.Internal.NPC, as: NPCInternal
  alias Helix.NPC.Model.NPC

  # FIXME: add factories as soon as this get more fields

  test "creation" do
    assert {:ok, _} = NPCInternal.create(%{})
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
