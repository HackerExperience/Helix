defmodule Helix.Entity.Make.Entity do

  alias Helix.Universe.NPC.Model.NPC
  alias Helix.Entity.Action.Entity, as: EntityAction

  def entity(npc = %NPC{}, _data \\ %{}) do
    {:ok, entity} = EntityAction.create_from_specialization(npc)
    entity
  end
end
