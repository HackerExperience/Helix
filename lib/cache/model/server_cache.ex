defmodule Helix.Cache.Model.ServerCache do

  use Ecto.Schema

  alias HELL.PK

  import Ecto.Changeset

  @cache_duration 60 * 60 * 24

  @type t :: %__MODULE__{
    server_id: PK.t,
    entity_id: PK.t,
    motherboard_id: PK.t,
    networks: List.t,
    storages: List.t,
    resources: map(),
    components: List.t,
    expiration_date: DateTime.t,
  }

  @creation_fields ~w/server_id entity_id motherboard_id networks storages resources components/a
  @update_fields ~w//a

  @primary_key false
  schema "server_cache" do
    field :server_id, PK,
      primary_key: true

    field :entity_id, PK
    field :motherboard_id, PK
    field :networks, {:array, :map}
    field :storages, {:array, PK}
    field :resources, :map
    field :components, {:array, PK}

    field :expiration_date, :utc_datetime
  end

  # @spec create_changeset(creation_params) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> add_expiration_date()
  end

  # @spec update_changeset(t, update_params) :: Ecto.Changeset.t
  def update_changeset(schema, params) do
    schema
    |> cast(params, @update_fields)
    |> add_expiration_date()
  end

  # @spec put_display_name(Ecto.Changeset.t) :: Ecto.Changeset.t
  defp add_expiration_date(changeset) do
    expire_ts = DateTime.to_unix(DateTime.utc_now()) + @cache_duration
    {:ok, expire_date} = DateTime.from_unix(expire_ts)
    put_change(changeset, :expiration_date, expire_date)
  end

  defmodule Query do

    alias Helix.Cache.Model.ServerCache

    import Ecto.Query, only: [where: 3]

    @spec by_server(Ecto.Queryable.t, PK.t) :: Ecto.Queryable.t
    def by_server(query \\ ServerCache, server_id),
      do: where(query, [s], s.server_id == ^server_id)

    @spec by_motherboard(Ecto.Queryable.t, PK.t) :: Ecto.Queryable.t
    def by_motherboard(query \\ ServerCache, motherboard_id),
      do: where(query, [s], s.motherboard_id == ^motherboard_id)
  end
end
