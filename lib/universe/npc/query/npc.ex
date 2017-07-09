defmodule Helix.Universe.NPC.Query.NPC do

  alias Helix.Universe.NPC.Internal.NPC, as: NPCInternal
  alias Helix.Universe.NPC.Model.NPC

  @spec fetch(HELL.PK.t) :: NPC.t | nil
  def fetch(npc_id),
    do: NPCInternal.fetch(npc_id)
end
