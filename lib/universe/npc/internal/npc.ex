defmodule Helix.Universe.NPC.Internal.NPC do

  alias Helix.Universe.NPC.Model.NPC
  alias Helix.Universe.Repo

  @spec fetch(NPC.id) ::
    NPC.t
    | nil
  def fetch(npc_id),
    do: Repo.get(NPC, npc_id)

  @spec create(NPC.creation_params) ::
    {:ok, NPC.t}
    | {:error, Ecto.Changeset.t}
  def create(params) do
    params
    |> NPC.create_changeset()
    |> Repo.insert()
  end

  @spec delete(NPC.t) ::
    :ok
  def delete(npc) do
    Repo.delete(npc)

    :ok
  end
end
