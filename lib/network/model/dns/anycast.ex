defmodule Helix.Network.Model.DNS.Anycast do

  use Ecto.Schema

  import Ecto.Changeset

  alias HELL.Constant
  alias Helix.Universe.NPC.Model.NPC

  @type t :: %__MODULE__{}

  @type creation_params :: %{
    :name => Constant.t,
    :npc_id => NPC.id
  }

  @one_npc_per_name :dns_anycast_npc_unique_index

  @creation_fields ~w/name npc_id/a

  @primary_key false

  schema "dns_anycast" do
    field :name, :string,
      primary_key: true

    field :npc_id, NPC.ID
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required([:name, :npc_id])
    |> unique_constraint(:npc_id, name: @one_npc_per_name)
  end

  defmodule Query do

    import Ecto.Query, only: [where: 3]

    alias Helix.Universe.NPC.Model.NPC
    alias Helix.Network.Model.DNS.Anycast

    @spec by_name(Ecto.Queryable.t, String.t) ::
      Ecto.Queryable.t
    def by_name(query \\ Anycast, name),
      do: where(query, [a], a.name == ^name)

    @spec by_npc(Ecto.Queryable.t, NPC.idtb) ::
      Ecto.Queryable.t
    def by_npc(query \\ Anycast, npc),
      do: where(query, [a], a.npc_id == ^npc)
  end
end
