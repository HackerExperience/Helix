defmodule HELM.NPC.Controller.NPCs do
  import Ecto.Query

  alias HELM.NPC.Model.Repo
  alias HELM.NPC.Model.NPCs, as: MdlNPCs

  def create(npc) do
    MdlNPCs.create_changeset(npc)
    |> Repo.insert()
  end

  def find(npc_id) do
    case Repo.get(MdlNPCs, npc_id) do
      nil -> {:error, :notfound}
      npc -> {:ok, npc}
    end
  end

  def delete(npc_id) do
    MdlNPCs
    |> where([s], s.npc_id == ^npc_id)
    |> Repo.delete_all()

    :ok
  end
end