defmodule Helix.Cache.Model.WebCache do

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias HELL.IPv4
  alias HELL.PK

  @type t :: %__MODULE__{
    network_id: PK.t,
    ip: IPv4.t,
    content: map,
    expiration_date: DateTime.t
  }

  @cache_duration 60 * 60 * 24 * 1000

  @creation_fields ~w/network_id ip content/a

  @primary_key false
  schema "web_cache" do
    field :network_id, PK,
      primary_key: true
    field :ip, IPv4,
      primary_key: true

    field :content, :map

    field :expiration_date, :utc_datetime
  end

  def new(network_id, ip, content) do
    %{
      network_id: network_id,
      ip: ip,
      content: content
    }
    |> create_changeset()
    |> Changeset.apply_changes()
  end

  def create_changeset(params = %__MODULE__{}),
    do: create_changeset(Map.from_struct(params))
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
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
    alias Helix.Network.Model.Network
    alias Helix.Cache.Model.WebCache

    @spec web_by_nip(Queryable.t, Network.idtb, Network.ip) ::
      Queryable.t
    def web_by_nip(query \\ WebCache, network, ip),
      do: where(query, [w], w.network_id == ^network and w.ip == ^ip)

    @spec filter_expired(Queryable.t) ::
      Queryable.t
    def filter_expired(query),
      do: where(query, [w], w.expiration_date >= fragment("now() AT TIME ZONE 'UTC'"))
  end
end
