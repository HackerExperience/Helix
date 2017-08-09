defmodule Helix.Network.Model.Web.Player do

  use Ecto.Schema

  import Ecto.Changeset

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

    import Ecto.Query, only: [where: 3]

    alias HELL.IPv4
    alias Helix.Network.Model.Web.Player

    @spec by_ip(Ecto.Queryable.t, IPv4.t) ::
      Ecto.Queryable.t
    def by_ip(query \\ Player, ip),
      do: where(query, [w], w.ip == ^ip)
  end
end
