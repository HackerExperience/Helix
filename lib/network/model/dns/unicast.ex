defmodule Helix.Network.Model.DNS.Unicast do

  use Ecto.Schema

  import Ecto.Changeset

  alias HELL.IPv4
  alias Helix.Network.Model.Network

  @type t :: %__MODULE__{}

  @type creation_params :: %{
    :network_id => Network.idtb,
    :name => String.t,
    :ip => IPv4.t
  }

  @one_nip_per_name :dns_unicast_nip_unique_index

  @creation_fields ~w/network_id name ip/a

  @primary_key false
  schema "dns_unicast" do
    field :network_id, Network.ID,
      primary_key: true
    field :name, :string,
      primary_key: true
    field :ip, IPv4
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required([:network_id, :name, :ip])
    |> unique_constraint(:ip, name: @one_nip_per_name)
  end

  defmodule Query do

    import Ecto.Query, only: [where: 3]

    alias Ecto.Queryable
    alias HELL.IPv4
    alias Helix.Network.Model.DNS.Unicast
    alias Helix.Network.Model.Network

    @spec by_net_and_name(Queryable.t, Network.idtb, String.t) ::
      Queryable.t
    def by_net_and_name(query \\ Unicast, network, name),
      do: where(query, [u], u.network_id == ^network and u.name == ^name)

    @spec by_nip(Queryable.t, Network.idtb, IPv4.t) ::
      Queryable.t
    def by_nip(query \\ Unicast, network, ip),
      do: where(query, [u], u.network_id == ^network and u.ip == ^ip)
  end
end
