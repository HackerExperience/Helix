defmodule Helix.Cache.Model.StorageCache do

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias HELL.PK
  alias Helix.Software.Model.Storage
  alias Helix.Cache.Model.Populate.Storage, as: StorageParams
  alias Helix.Cache.Model.Cacheable

  @cache_duration 60 * 60 * 24 * 1000

  @type t :: %__MODULE__{
    storage_id: PK.t,
    server_id: PK.t,
    expiration_date: DateTime.t
  }

  @creation_fields ~w/storage_id server_id/a

  @primary_key false
  schema "storage_cache" do
    field :storage_id, PK,
      primary_key: true
    field :server_id, PK

    field :expiration_date, :utc_datetime
  end

  def new(storage_id, server_id) do
    %__MODULE__{
      storage_id: storage_id,
      server_id: server_id
    }
    |> Cacheable.format_input()
  end

  @spec create_changeset(StorageParams.t) ::
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
    alias Helix.Software.Model.Storage
    alias Helix.Cache.Model.StorageCache

    @spec by_storage(Queryable.t, Storage.id) ::
      Queryable.t
    def by_storage(query \\ StorageCache, storage_id),
      do: where(query, [s], s.storage_id == ^storage_id)

    @spec filter_expired(Queryable.t) ::
      Queryable.t
    def filter_expired(query),
      do: where(query, [s], s.expiration_date >= fragment("now()"))
  end
end
