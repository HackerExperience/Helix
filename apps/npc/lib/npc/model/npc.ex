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
  schema "npcs" do
    field :npc_id, HELL.PK,
      primary_key: true

    timestamps()
  end

  @spec create_changeset(%{}) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> put_primary_key()
  end

  @spec put_primary_key(Ecto.Changeset.t) :: Ecto.Changeset.t
  defp put_primary_key(changeset) do
    ip = PK.generate([0x0006, 0x0000, 0x0000])

    changeset
    |> cast(%{npc_id: ip}, [:npc_id])
  end
end