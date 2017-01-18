defmodule Helix.NPC.Controller.NPC do

  alias Helix.NPC.Repo
  alias Helix.NPC.Model.NPC
  import Ecto.Query, only: [where: 3]

  @spec create(%{}) :: {:ok, NPC.t} | {:error, Ecto.Changeset.t}
  def create(params) do
    params
    |> NPC.create_changeset()
    |> Repo.insert()
  end

  @spec find(HELL.PK.t) :: {:ok, NPC.t} | {:error, :notfound}
  def find(npc_id) do
    case Repo.get_by(NPC, npc_id: npc_id) do
      nil ->
        {:error, :notfound}
      npc ->
        {:ok, npc}
    end
  end

  @spec delete(HELL.PK.t) :: no_return
  def delete(npc_id) do
    NPC
    |> where([n], n.npc_id == ^npc_id)
    |> Repo.delete_all()

    :ok
  end
end