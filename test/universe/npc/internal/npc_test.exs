defmodule Helix.Universe.NPC.Internal.NPCTest do

  use Helix.Test.Case.Integration

  alias Helix.Universe.NPC.Internal.NPC, as: NPCInternal
  alias Helix.Universe.NPC.Model.NPC
  alias Helix.Test.Universe.NPC.Helper, as: NPCHelper

  test "creation" do
    # Note: this is pretty much useless, since we rarely ever want *only* to
    # add an entry at the NPC table. Usually we want a specialization of this,
    # like `create_bank` or `create_mission_target`. Once we add specializations
    # we should adapt this test
    npc = %{npc_type: :download_center}
    assert {:ok, _} = NPCInternal.create(npc)
  end

  describe "fetching" do
    test "success by id" do
      {npc, _} = NPCHelper.random()
      assert %NPC{} = NPCInternal.fetch(npc.id)
    end

    test "fails when npc doesn't exist" do
      refute NPCInternal.fetch(NPC.ID.generate())
    end
  end

  test "delete/1" do
    {npc, _} = NPCHelper.random()
    npc_from_db = NPCInternal.fetch(npc.id)

    assert npc
    NPCInternal.delete(npc_from_db)
    refute NPCInternal.fetch(npc.id)
  end
end
