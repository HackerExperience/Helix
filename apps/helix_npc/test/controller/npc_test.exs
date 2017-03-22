defmodule Helix.NPC.Controller.NPCTest do

  use ExUnit.Case, async: true

  alias HELL.PK
  alias Helix.NPC.Controller.NPC, as: NPCController
  alias Helix.NPC.Model.NPC, as: NPC

  @moduletag :integration

  test "create/1" do
    assert {:ok, _} = NPCController.create(%{})
  end

  describe "find/1" do
    test "success" do
      {:ok, npc} = NPCController.create(%{})
      assert {:ok, ^npc} = NPCController.find(npc.npc_id)
    end

    test "failure" do
      assert {:error, :notfound} == NPCController.find(PK.pk_for(NPC))
    end
  end

  test "delete/1 idempotency" do
    {:ok, npc} = NPCController.create(%{})
    assert :ok = NPCController.delete(npc.npc_id)
    assert :ok = NPCController.delete(npc.npc_id)
  end
end