defmodule Helix.Network.Model.DNS.Anycast do

  use Ecto.Schema

  import Ecto.Changeset

  alias HELL.PK

  @type t :: %__MODULE__{}

  @type creation_params :: %{
    :name => Constant.t,
    :npc_id => PK
  }

  @one_npc_per_name :dns_anycast_id_npc_unique_index

  @creation_fields ~w/name npc_id/a

  @primary_key false

  schema "dns_anycast" do
    field :name, :string,
      primary_key: true

    field :npc_id, PK
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required([:name, :npc_id])
    |> unique_constraint(:npc_id, name: @one_npc_per_name)
  end

  defmodule Query do

    alias Helix.Network.Model.DNS.Anycast

    import Ecto.Query, only: [where: 3]

    @spec by_name(Ecto.Queryable.t, Constant.t) :: Ecto.Queryable.t
    def by_name(query \\ Anycast, name),
      do: where(query, [a], a.name == ^name)

    @spec by_npc(Ecto.Queryable.t, PK.t) :: Ecto.Queryable.t
    def by_npc(query \\ Anycast, npc_id),
      do: where(query, [a], a.npc_id == ^npc_id)
  end
end
