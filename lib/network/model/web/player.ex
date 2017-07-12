defmodule Helix.Network.Model.Web.Player do

  use Ecto.Schema

  import Ecto.Changeset

  alias HELL.PK
  alias HELL.IPv4

  @type t :: %__MODULE__{}

  @type creation_params :: %{
    :ip => IPv4,
    :content => String.t
  }

  @creation_fields ~w/ip content/a

  @primary_key false

  schema "webservers" do
    field :ip, IPv4,
      primary_key: true

    field :content, :string,
      size: 2048
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required([:content])
  end

  defmodule Query do

    alias Helix.Network.Model.Web.Player

    import Ecto.Query, only: [where: 3]

    @spec by_ip(Ecto.Queryable.t, IPv4) :: Ecto.Queryable.t
    def by_ip(query \\ Player, ip),
      do: where(query, [w], w.ip == ^ip)
  end
end
