defmodule HELM.NPC.Model.NPC do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:npc_id, :string, autogenerate: false}

  schema "npcs" do
    timestamps
  end

  @creation_fields ~w()

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> put_uuid()
  end

  defp put_uuid(changeset) do
    if changeset.valid?,
      do: Ecto.Changeset.put_change(changeset, :npc_id, HELL.ID.generate("NPC")),
      else: changeset
  end
end