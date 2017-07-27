defmodule Helix.Cache.Model.NetworkCache do

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias HELL.PK
  alias HELL.IPv4
  alias Helix.Hardware.Model.NetworkConnection
  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Server
  alias Helix.Cache.Model.Populate.Network, as: NetworkParams

  @cache_duration 60 * 60 * 24 * 1000

  @type t :: %__MODULE__{
    network_id: Network.id,
    ip: NetworkConnection.ip,
    server_id: Server.id,
    expiration_date: DateTime.t
  }

  @creation_fields ~w/network_id ip server_id/a

  @primary_key false
  schema "network_cache" do
    field :network_id, PK,
      primary_key: true
    field :ip, IPv4,
      primary_key: true
    field :server_id, PK

    field :expiration_date, :utc_datetime
  end

  @spec create_changeset(NetworkParams.t) ::
    Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(Map.from_struct(params), @creation_fields)
    |> add_expiration_date()
  end

  @spec add_expiration_date(Changeset.t) ::
    Changeset.t
  defp add_expiration_date(changeset) do
    expire_date =
      DateTime.utc_now()
      |> DateTime.to_unix(:millisecond)
      |> Kernel.+(@cache_duration)
      |> DateTime.from_unix!(:millisecond)

    put_change(changeset, :expiration_date, expire_date)
  end

  defmodule Query do

    import Ecto.Query, only: [where: 3]

    alias Ecto.Queryable
    alias Helix.Hardware.Model.NetworkConnection
    alias Helix.Network.Model.Network
    alias Helix.Cache.Model.NetworkCache

    @spec by_nip(Queryable.t, Network.id, NetworkConnection.ip) ::
      Queryable.t
    def by_nip(query \\ NetworkCache, network_id, ip),
      do: where(query, [n], n.network_id == ^network_id and n.ip == ^ip)

    @spec filter_expired(Queryable.t) ::
      Queryable.t
    def filter_expired(query),
      do: where(query, [s], s.expiration_date >= fragment("now()"))
  end
end
