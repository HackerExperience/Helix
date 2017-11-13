defmodule Helix.Universe.NPC.Action.NPC do

  alias Helix.Universe.NPC.Model.NPC
  alias Helix.Universe.NPC.Internal.NPC, as: NPCInternal

  @spec create(NCP.type) ::
    {:ok, NPC.t}
    | {:error, :internal}
  def create(type) do
    params = %{npc_type: type}

    case NPCInternal.create(params) do
      {:ok, npc} ->
        {:ok, npc}

      {:error, _} ->
        {:error, :internal}
    end
  end
end
