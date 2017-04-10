defmodule Helix.NPC.Controller.NPCTest do

  use Helix.Test.IntegrationCase

  alias HELL.TestHelper.Random
  alias Helix.NPC.Controller.NPC, as: NPCController
  alias Helix.NPC.Model.NPC

  # FIXME: add factories as soon as this get more fields

  test "creation" do
    assert {:ok, _} = NPCController.create(%{})
  end

  describe "fetching" do
    test "success by id" do
      {:ok, npc} = NPCController.create(%{})
      assert %NPC{} = NPCController.fetch(npc.npc_id)
    end

    test "fails when npc with id doesn't exist" do
      bogus = Random.pk()
      refute NPCController.fetch(bogus)
    end
  end

  test "deleting is idempotent" do
    {:ok, npc} = NPCController.create(%{})
    NPCController.delete(npc.npc_id)
    NPCController.delete(npc.npc_id)
    refute NPCController.fetch(npc.npc_id)
  end
end
