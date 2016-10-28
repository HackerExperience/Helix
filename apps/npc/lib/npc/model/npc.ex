defmodule HELM.NPC.Model.NPC do
  use Ecto.Schema
  import Ecto.Changeset

  alias HELL.UUID, as: HUUID

  @primary_key {:npc_id, :binary_id, autogenerate: false}

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
      do: put_change(changeset, :npc_id, uuid()),
      else: changeset
  end

  defp uuid,
    do: HUUID.create!("03")
end