defmodule Helix.Universe.NPC.Make.NPC do

  # TODO
  alias Helix.Universe.NPC.Internal.NPC, as: NPCInternal

  def story_char(_data \\ %{}) do
    {:ok, npc} =
      %{npc_type: :story_char}
      |> NPCInternal.create()

    npc
  end
end
