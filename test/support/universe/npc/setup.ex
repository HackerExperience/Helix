defmodule Helix.Test.Universe.NPC.Setup do

  alias Helix.Universe.NPC.Internal.NPC, as: NPCInternal

  def npc do
    {:ok, npc} = NPCInternal.create(%{npc_type: :download_center})
    npc
  end
end
