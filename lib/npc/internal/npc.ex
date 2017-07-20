defmodule Helix.NPC.Internal.NPC do

  alias Helix.NPC.Repo
  alias Helix.NPC.Model.NPC

  import Ecto.Query, only: [where: 3]

  @spec create(map) ::
    {:ok, NPC.t}
    | {:error, Ecto.Changeset.t}
  def create(params) do
    params
    |> NPC.create_changeset()
    |> Repo.insert()
  end

  @spec fetch(NPC.id) ::
    NPC.t
    | nil
  def fetch(npc_id),
    do: Repo.get(NPC, npc_id)

  @spec delete(NPC.id) ::
    :ok
  def delete(npc_id) do
    NPC
    |> where([n], n.npc_id == ^npc_id)
    |> Repo.delete_all()

    :ok
  end
end
