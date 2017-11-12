defmodule Helix.Network.Model.Web.Player do

  use Ecto.Schema

  import Ecto.Changeset

  alias HELL.IPv4
  alias Helix.Network.Model.Network

  @type t :: %__MODULE__{}

  @type creation_params :: %{
    ip: Network.ip,
    content: content
  }

  @type content :: String.t

  @max_content_size 2048

  @creation_fields [:ip, :content]

  @primary_key false
  schema "webservers" do
    field :ip, IPv4,
      primary_key: true

    field :content, :string
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required([:ip, :content])
    |> validate_length(:content, max: @max_content_size)
  end

  defmodule Query do

    import Ecto.Query, only: [where: 3]

    alias Ecto.Queryable
    alias Helix.Network.Model.Network
    alias Helix.Network.Model.Web.Player

    @spec by_ip(Queryable.t, Network.ip) ::
      Queryable.t
    def by_ip(query \\ Player, ip),
      do: where(query, [w], w.ip == ^ip)
  end
end
