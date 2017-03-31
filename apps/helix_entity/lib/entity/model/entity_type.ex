defmodule Helix.Entity.Model.EntityType do

  use Ecto.Schema

  alias HELL.Constant

  @type t :: %__MODULE__{
    entity_type: Constant.t
  }

  @primary_key false
  schema "entity_types" do
    field :entity_type, Constant,
      primary_key: true
  end

  @doc false
  def possible_types do
    ~w/account clan npc/a
  end

  @doc false
  def type_implementations do
    %{
      account: Helix.Account.Model.Account,
      clan: Helix.Clan.Model.Clan,
      npc: Helix.NPC.Model.NPC
    }
  end
end
