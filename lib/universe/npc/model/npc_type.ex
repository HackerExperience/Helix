defmodule Helix.Universe.NPC.Model.NPCType do

  use Ecto.Schema

  alias HELL.Constant

  @type types ::
    :download_center
    | :bank
    | :atm

  @type t :: %__MODULE__{
    npc_type: Constant.t
  }

  @primary_key false
  schema "npc_types" do
    field :npc_type, Constant,
      primary_key: true
  end

  @doc false
  def possible_types do
    ~w/download_center bank atm/a
  end
end
