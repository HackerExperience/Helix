defmodule Helix.Cache.Model.ServerCache do

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias HELL.IPv4
  alias Helix.Entity.Model.Entity
  alias Helix.Hardware.Model.Component
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.Storage
  alias Helix.Cache.Model.Populate.Server, as: ServerParams

  @cache_duration 60 * 60 * 24 * 1000

  @type t :: %__MODULE__{
    server_id: Server.id,
    entity_id: Entity.id,
    motherboard_id: Component.id,
    # Note that this is a "cached" version of the NIP and uses the id as a
    # string
    networks: [%{network_id: String.t, ip: IPv4.t}],
    storages: [Storage.id],
    resources: map,
    components: [Component.id],
    expiration_date: DateTime.t
  }

  @creation_fields ~w/
    server_id
    entity_id
    motherboard_id
    networks
    storages
    resources
    components/a

  @primary_key false
  schema "server_cache" do
    field :server_id, Server.ID,
      primary_key: true

    field :entity_id, Entity.ID
    field :motherboard_id, Component.ID
    field :networks, {:array, :map}
    field :storages, {:array, Storage.ID}
    field :resources, :map
    field :components, {:array, Component.ID}

    field :expiration_date, :utc_datetime
  end

  @spec create_changeset(ServerParams.t) ::
    Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(Map.from_struct(params), @creation_fields)
    |> workaround_to_add_nil_values(params)
    |> add_expiration_date()
  end

  # Fix for https://github.com/elixir-ecto/ecto/issues/2017
  # Basically, Ecto won't add `nil` values on upsert (insert + :replace_all),
  # even when using changeset and `cast/3`. `put_change` won't work either.
  defp workaround_to_add_nil_values(changeset, params) do
    Enum.reduce(@creation_fields, changeset, fn(field, cs) ->
      value = Map.get(params, field)
      if is_nil(value) do
        force_change(cs, field, value)
      else
        cs
      end
    end)
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
