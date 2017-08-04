defmodule Helix.NPC.Model.NPC do

  use Ecto.Schema
  use HELL.ID, field: :npc_id, meta: [0x0002]

  @type t :: %__MODULE__{
    npc_id: id,
    inserted_at: NaiveDateTime.t,
    updated_at: NaiveDateTime.t
  }

  schema "npcs" do
    field :npc_id, ID,
      primary_key: true

    timestamps()
  end
end
