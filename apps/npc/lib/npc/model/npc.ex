defmodule Helix.NPC.Model.NPC do

  use Ecto.Schema

  alias HELL.PK

  import Ecto.Changeset

  @type t :: %__MODULE__{
    npc_id: PK.t,
    inserted_at: NaiveDateTime.t,
    updated_at: NaiveDateTime.t
  }

  @creation_fields ~w//a

  @primary_key false
  @ecto_autogenerate {:npc_id, {PK, :pk_for, [__MODULE__]}}
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