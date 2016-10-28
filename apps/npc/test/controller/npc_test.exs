defmodule HELM.NPC.Controller.NPCTest do
  use ExUnit.Case

  alias HELL.UUID, as: HUUID
  alias HELM.NPC.Controller.NPC, as: CtrlNPC

  test "create/1" do
    assert {:ok, _} = CtrlNPC.create(%{})
  end

  describe "find/1" do
    test "success" do
      {:ok, npc} = CtrlNPC.create(%{})
      assert {:ok, ^npc} = CtrlNPC.find(npc.npc_id)
    end

    test "failure" do
      assert {:error, :notfound} = CtrlNPC.find(UUID.uuid4())
    end
  end

  test "delete/1 idempotency" do
    {:ok, npc} = CtrlNPC.create(%{})
    assert :ok = CtrlNPC.delete(npc.npc_id)
    assert :ok = CtrlNPC.delete(npc.npc_id)
  end
end