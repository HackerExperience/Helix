defmodule Helix.Cache.Model.ServerCache do

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias HELL.PK
  alias Helix.Entity.Model.Entity
  alias Helix.Hardware.Model.Component
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.Storage

  @cache_duration 60 * 60 * 24

  @type t :: %__MODULE__{
    server_id: Server.id,
    entity_id: Entity.id,
    motherboard_id: Component.id,
    networks: list,
    storages: [Storage.id],
    resources: map,
    components: [Component.id],
    expiration_date: DateTime.t
  }

  @type creation_params :: %{
    server_id: Server.id,
    entity_id: Entity.id,
    motherboard_id: Component.id,
    networks: list,
    storages: [Storage.id],
    resources: map(),
    components: [Component.id]
  }

  @type update_params :: %{
    optional(:server_id) => Server.id,
    optional(:entity_id) => Entity.id,
    optional(:motherboard_id) => Component.id,
    optional(:networks) => list,
    optional(:storages) => [Storage.id],
    optional(:resources) => map(),
    optional(:components) => [Component.id]
  }

  @creation_fields ~w/
    server_id
    entity_id
    motherboard_id
    networks
    storages
    resources
    components/a
  @update_fields ~w/
    server_id
    entity_id
    motherboard_id
    networks
    storages
    resources
    components/a

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

  @spec create_changeset(creation_params) ::
    Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> add_expiration_date()
  end

  @spec update_changeset(t | Changeset.t, update_params) ::
    Changeset.t
  def update_changeset(schema, params) do
    schema
    |> cast(params, @update_fields)
    |> add_expiration_date()
  end

  @spec add_expiration_date(Changeset.t) ::
    Changeset.t
  defp add_expiration_date(changeset) do
    expire_date =
      DateTime.utc_now()
      |> DateTime.to_unix(:microsecond)
      |> Kernel.+(@cache_duration)
      |> DateTime.from_unix!(:microsecond)

    put_change(changeset, :expiration_date, expire_date)
  end

  defmodule Query do

    import Ecto.Query, only: [where: 3]

    alias Ecto.Queryable
    alias Helix.Entity.Model.Entity
    alias Helix.Hardware.Model.Component
    alias Helix.Server.Model.Server
    alias Helix.Cache.Model.ServerCache

    @spec by_server(Queryable.t, Server.id) ::
      Queryable.t
    def by_server(query \\ ServerCache, server_id),
      do: where(query, [s], s.server_id == ^server_id)

    @spec by_motherboard(Queryable.t, Component.id) ::
      Queryable.t
    def by_motherboard(query \\ ServerCache, motherboard_id),
      do: where(query, [s], s.motherboard_id == ^motherboard_id)

    @spec by_entity(Queryable.t, Entity.id) ::
      Queryable.t
    def by_entity(query \\ ServerCache, entity_id),
      do: where(query, [s], s.entity_id == ^entity_id)

    @spec filter_expired(Queryable.t) ::
      Queryable.t
    def filter_expired(query),
      do: where(query, [s], s.expiration_date >= fragment("now()"))
  end
end
