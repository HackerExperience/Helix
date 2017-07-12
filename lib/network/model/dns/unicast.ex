defmodule Helix.Network.Model.DNS.Unicast do

  use Ecto.Schema

  alias HELL.IPv4

  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @type creation_params :: %{
    :name => Constant.t,
    :ip => IPv4.t
  }

  @one_ip_per_name :dns_unicat_id_ip_unique_index

  @creation_fields ~w/name ip/a

  @primary_key false

  schema "dns_unicast" do
    field :name, :string,
      primary_key: true

    field :ip, IPv4
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required([:name, :ip])
    |> unique_constraint(:ip, name: @one_ip_per_name)
  end

  defmodule Query do

    alias Helix.Network.Model.DNS.Unicast

    import Ecto.Query, only: [where: 3]

    @spec by_name(Ecto.Queryable.t, Constant.t) :: Ecto.Queryable.t
    def by_name(query \\ Unicast, name),
      do: where(query, [u], u.name == ^name)

    @spec by_ip(Ecto.Queryable.t, IPv4.t) :: Ecto.Queryable.t
    def by_ip(query \\ Unicast, ip),
      do: where(query, [u], u.ip == ^ip)
  end
end
