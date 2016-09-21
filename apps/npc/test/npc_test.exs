defmodule HELM.NPCTest do
  use ExUnit.Case

  alias HELF.Broker
  alias HELM.NPC

  test "the truth" do
    assert 1 + 1 == 2
  end

  test "npc creation" do
    {:ok, _} = NPC.Controller.new_npc(%{})
  end

  test "npc creation using the broker" do
    {:ok, _} = Broker.call("npc:create", %{})
  end

  test "npc removal" do
    {:ok, npc} = NPC.Controller.new_npc(%{})
    {:ok, _} = NPC.Controller.remove_npc(npc.npc_id)
  end

  test "npc removal using the broker" do
    {:ok, npc} = Broker.call("npc:create", %{})
    {:ok, _} = Broker.call("npc:remove", %{npc_id: npc.npc_id})
  end
end
