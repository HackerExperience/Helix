defmodule Helix.Universe.NPC.Query.NPC do

  alias Helix.Entity.Model.Entity
  alias Helix.Universe.NPC.Internal.NPC, as: NPCInternal
  alias Helix.Universe.NPC.Model.NPC

  @spec fetch(Entity.id | NPC.id) ::
    NPC.t
    | nil
  def fetch(entity = %Entity.ID{}),
    do: fetch(%NPC.ID{id: entity.id})
  def fetch(npc_id),
    do: NPCInternal.fetch(npc_id)
end
