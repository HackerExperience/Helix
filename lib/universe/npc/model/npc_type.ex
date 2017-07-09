defmodule Helix.Universe.NPC.Model.NPCType do

  use Ecto.Schema

  alias HELL.Constant

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
    # Review: HALP, I need those atoms because binary_to_existing_atom/2.
    # ~w/download_center bank atm/a
    [:download_center, :bank, :atm]
  end
end
