defmodule Helix.Universe.NPC.Model.NPCType do

  use Ecto.Schema

  alias HELL.Constant

  @type type ::
    :download_center
    | :bank
    | :atm
    | :story_char

  @type t :: %__MODULE__{
    npc_type: type
  }

  @npc_types [:download_center, :bank, :atm, :story_char]

  @primary_key false
  schema "npc_types" do
    field :npc_type, Constant,
      primary_key: true
  end

  @doc false
  def possible_types,
    do: @npc_types
end
