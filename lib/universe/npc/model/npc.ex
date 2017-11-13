defmodule Helix.Universe.NPC.Model.NPC do

  use Ecto.Schema
  use HELL.ID, field: :npc_id, meta: [0x0002]

  import Ecto.Changeset

  alias HELL.Constant
  alias Helix.Universe.Bank.Model.Bank
  alias Helix.Universe.Bank.Model.ATM
  alias Helix.Universe.NPC.Model.NPCType

  @type t :: %__MODULE__{
    npc_id: id,
    npc_type: NPCType.type,
    inserted_at: NaiveDateTime.t,
    updated_at: NaiveDateTime.t
  }

  @type creation_params :: %{
    :npc_type => NPCType.type
  }

  @creation_fields ~w/npc_type/a

  @primary_key false
  schema "npcs" do
    field :npc_id, ID,
      primary_key: true

    field :npc_type, Constant

    has_one :bank, Bank,
      foreign_key: :bank_id,
      references: :npc_id

    has_one :atm, ATM,
      foreign_key: :atm_id,
      references: :npc_id

    timestamps()
  end

  @spec create_changeset(creation_params) ::
    Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(:npc_type)
    |> validate_inclusion(:npc_type, NPCType.possible_types())
  end

  defmodule Query do

    import Ecto.Query, only: [where: 3]

    alias Ecto.Queryable
    alias Helix.Universe.NPC.Model.NPC

    @spec by_id(Queryable.t, NPC.idtb) ::
      Queryable.t
    def by_id(query \\ NPC, npc),
      do: where(query, [n], n.npc_id == ^npc)
  end
end
