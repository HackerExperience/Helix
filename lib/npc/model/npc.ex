defmodule Helix.NPC.Model.NPC do

  use Ecto.Schema

  import Ecto.Changeset

  alias HELL.PK

  @type id :: PK.t
  @type t :: %__MODULE__{
    npc_id: id,
    inserted_at: NaiveDateTime.t,
    updated_at: NaiveDateTime.t
  }

  @creation_fields ~w//a

  @primary_key false
  @ecto_autogenerate {:npc_id, {PK, :pk_for, [:npc_npc]}}
  schema "npcs" do
    field :npc_id, HELL.PK,
      primary_key: true

    timestamps()
  end

  @spec create_changeset(%{}) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
  end
end
