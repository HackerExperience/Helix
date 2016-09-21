defmodule HELM.NPC.Schema do
  use Ecto.Schema

  import Ecto.Changeset

  alias HELM.NPC

  @primary_key {:npc_id, :string, autogenerate: false}

  schema "npc" do
    timestamps
  end

  @creation_fields ~w(npc_id)

  def create_changeset(entity, params \\ :empty) do
    entity
    |> cast(params, @creation_fields)
    |> put_uuid()
  end

  defp put_uuid(changeset) do
    if changeset.valid?,
      do: Ecto.Changeset.put_change(changeset, :entity_id, HELL.ID.generate("NPC")),
      else: changeset
  end
end
