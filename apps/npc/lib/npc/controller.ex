defmodule HELM.NPC.Controller do
  import Ecto.Query

  alias HELF.Broker
  alias HELM.NPC

  def new_npc(npc) do
    changeset = NPC.Schema.create_changeset(npc)

    case NPC.Repo.insert(changeset) do
      {:ok, operation} -> {:ok, operation}
      {:error, msg} -> {:error, msg}
    end
  end

end
