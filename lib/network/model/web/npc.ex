defmodule Helix.Network.Model.Web.NPC do

  use Ecto.Schema

  import Ecto.Changeset

  alias HELL.PK
  alias HELL.IPv4

  @type t :: %__MODULE__{}

  @type creation_params :: %{
    :ip => IPv4,
    :npc_id => PK,
    :content => map()
  }

  @creation_fields ~w/ip npc_id content/a

  @primary_key false

  schema "webserver_npc_cache" do
    field :ip, IPv4,
      primary_key: true

    field :npc_id, PK
    field :content, :map
    field :expiration_time, :utc_datetime
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required([:ip, :npc_id, :content])
  end

  defmodule Query do

    alias Helix.Network.Model.Web.NPC

    import Ecto.Query, only: [where: 3]

    @spec by_ip(Ecto.Queryable.t, IPv4) :: Ecto.Queryable.t
    def by_ip(query \\ NPC, ip),
      do: where(query, [n], n.ip == ^ip)
  end
end
