defmodule Helix.Network.Model.DNS.Unicast do

  use Ecto.Schema

  import Ecto.Changeset

  alias HELL.IPv4
  alias Helix.Network.Model.Network

  @type t :: %__MODULE__{}

  @type creation_params :: %{
    :name => String.t,
    :network_id => Network.id,
    :ip => IPv4.t
  }

  @one_nip_per_name :dns_unicast_nip_unique_index

  @creation_fields ~w/name network_id ip/a

  @primary_key false

  schema "dns_unicast" do
    field :name, :string,
      primary_key: true
    field :network_id, Network.ID,
      primary_key: true
    field :ip, IPv4
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required([:name, :network_id, :ip])
    |> unique_constraint(:ip, name: @one_nip_per_name)
  end

  defmodule Query do

    import Ecto.Query, only: [where: 3]

    alias HELL.IPv4
    alias Helix.Network.Model.DNS.Unicast
    alias Helix.Network.Model.Network

    @spec by_name(Ecto.Queryable.t, String.t, Network.idtb) ::
      Ecto.Queryable.t
    def by_name(query \\ Unicast, name, network),
      do: where(query, [u], u.name == ^name and u.network_id == ^network)

    @spec by_nip(Ecto.Queryable.t, Network.idtb, IPv4.t) ::
      Ecto.Queryable.t
    def by_nip(query \\ Unicast, network, ip),
      do: where(query, [u], u.network_id == ^network and u.ip == ^ip)
  end
end
