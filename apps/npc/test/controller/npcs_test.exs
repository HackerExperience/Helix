defmodule HELM.NPC.Controller.NPCTest do
  use ExUnit.Case

  alias HELM.NPC.Controller.NPC, as: CtrlNPCs

  test "create/1" do
    assert {:ok, _} = CtrlNPCs.create(%{})
  end

  describe "find/1" do
    test "success" do
      {:ok, npc} = CtrlNPCs.create(%{})
      assert {:ok, ^npc} = CtrlNPCs.find(npc.npc_id)
    end

    test "failure" do
      assert {:error, :notfound} = CtrlNPCs.find("")
    end
  end

  test "delete/1 idempotency" do
    {:ok, npc} = CtrlNPCs.create(%{})
    assert :ok = CtrlNPCs.delete(npc.npc_id)
    assert :ok = CtrlNPCs.delete(npc.npc_id)
  end
end