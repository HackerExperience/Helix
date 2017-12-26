defmodule Helix.Entity.Make.Entity do

  alias Helix.Universe.NPC.Model.NPC
  alias Helix.Entity.Action.Entity, as: EntityAction
  alias Helix.Entity.Model.Entity

  @spec entity(NPC.t) ::
    Entity.t
  def entity(npc = %NPC{}) do
    {:ok, entity, _} = EntityAction.create_from_specialization(npc)
    entity
  end
end
