defmodule Helix.Universe.NPC.Model.NPC do

  use Ecto.Schema

  alias HELL.PK
  alias HELL.Constant
  alias Helix.Universe.NPC.Model.NPCType

  import Ecto.Changeset

  @type id :: PK.t
  @type t :: %__MODULE__{
    npc_id: PK.t,
    inserted_at: NaiveDateTime.t,
    updated_at: NaiveDateTime.t
  }

  @type creation_params :: %{
    :npc_type => Constant.t
  }

  @creation_fields ~w/npc_type/a

  @primary_key false
  @ecto_autogenerate {:npc_id, {PK, :pk_for, [:universe_npc]}}
  schema "npcs" do
    field :npc_id, HELL.PK,
      primary_key: true

    field :npc_type, Constant

    timestamps()
  end

  @spec create_changeset(%{}) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(:npc_type)
    |> validate_inclusion(:npc_type, NPCType.possible_types())
  end

  defmodule Query do
    alias Helix.Universe.NPC.Model.NPC

    import Ecto.Query, only: [where: 3]

    @spec by_id(Ecto.Queryable.t, HELL.PK.t) :: Ecto.Queryable.t
    def by_id(query \\ NPC, npc_id),
      do: where(query, [n], n.npc_id == ^npc_id)
  end

end
