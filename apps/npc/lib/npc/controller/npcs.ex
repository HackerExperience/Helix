defmodule HELM.NPC.Controller do
  import Ecto.Query

  alias HELF.Broker
  alias HELM.NPC

  def find_npc(npc_id) do
    NPC.Repo.get(NPC.Schema, npc_id)
  end

  def new_npc(npc) do
    changeset = NPC.Schema.create_changeset(npc)

    case NPC.Repo.insert(changeset) do
      {:ok, operation} -> {:ok, operation}
      {:error, msg} -> {:error, msg}
    end
  end

  def remove_npc(npc_id) do
    with npc when not is_nil(npc) <- find_npc(npc_id),
         {:ok, result} <- NPC.Repo.delete(npc) do
      {:ok, "The NPC was removed."}
    else
      :error -> {:error, "Shit Happens"}
    end
  end

end
