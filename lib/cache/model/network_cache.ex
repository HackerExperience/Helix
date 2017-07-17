defmodule Helix.Cache.Model.NetworkCache do

  use Ecto.Schema

  alias HELL.PK
  alias HELL.IPv4

  import Ecto.Changeset

  @cache_duration 60 * 60 * 24

  @type t :: %__MODULE__{
    network_id: PK.t,
    ip: IPv4.t,
    server_id: PK.t,
    expiration_date: DateTime.t
  }

  @type creation_params :: %__MODULE__{
    network_id: PK.t,
    ip: IPv4.t,
    server_id: PK.t,
  }

  @type update_params :: %__MODULE__{
    network_id: PK.t,
    ip: IPv4.t,
    server_id: PK.t,
  }

  @creation_fields ~w/network_id ip server_id/a
  @update_fields ~w/network_id ip server_id/a

  @primary_key false
  schema "network_cache" do
    field :network_id, PK,
      primary_key: true
    field :ip, IPv4,
      primary_key: true
    field :server_id, PK

    field :expiration_date, Ecto.DateTime
  end

  @spec create_changeset(creation_params) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> add_expiration_date()
  end

  @spec update_changeset(t, update_params) :: Ecto.Changeset.t
  def update_changeset(schema, params) do
    schema
    |> cast(params, @update_fields)
    |> add_expiration_date()
  end

  @spec add_expiration_date(Ecto.Changeset.t) :: Ecto.Changeset.t
  defp add_expiration_date(changeset) do
    expire_ts = DateTime.to_unix(DateTime.utc_now(), :microsecond) + @cache_duration
    expire_date = Ecto.DateTime.from_unix!(expire_ts, :microsecond)
    put_change(changeset, :expiration_date, expire_date)
  end

  defmodule Query do

    alias Helix.Cache.Model.NetworkCache

    import Ecto.Query, only: [where: 3]

    @spec by_nip(Ecto.Queryable.t, PK.t, IPV4.t) :: Ecto.Queryable.t
    def by_nip(query \\ NetworkCache, network_id, ip),
      do: where(query, [n], n.network_id == ^network_id and n.ip == ^ip)

    @spec filter_expired(Ecto.Queryable.t) :: Ecto.Queryable.t
    def filter_expired(query),
      do: where(query, [s], s.expiration_date >= ^Ecto.DateTime.utc())
  end
end
