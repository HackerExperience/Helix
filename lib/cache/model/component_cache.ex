defmodule Helix.Cache.Model.ComponentCache do

  use Ecto.Schema

  alias HELL.PK

  import Ecto.Changeset

  @cache_duration 60 * 60 * 24

  @type t :: %__MODULE__{
    component_id: PK.t,
    motherboard_id: PK.t,
    expiration_date: DateTime.t
  }

  @type creation_params :: %__MODULE__{
    component_id: PK.t,
    motherboard_id: PK.t,
  }

  @type update_params :: %__MODULE__{
    component_id: PK.t,
    motherboard_id: PK.t,
  }

  @creation_fields ~w/component_id motherboard_id/a
  @update_fields ~w/component_id motherboard_id/a

  @primary_key false
  schema "component_cache" do
    field :component_id, PK,
      primary_key: true
    field :motherboard_id, PK

    field :expiration_date, :utc_datetime
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
    expire_ts = DateTime.to_unix(DateTime.utc_now()) + @cache_duration
    {:ok, expire_date} = DateTime.from_unix(expire_ts)
    put_change(changeset, :expiration_date, expire_date)
  end

  defmodule Query do

    alias Helix.Cache.Model.ComponentCache

    import Ecto.Query, only: [where: 3]

    @spec by_component(Ecto.Queryable.t, PK.t) :: Ecto.Queryable.t
    def by_component(query \\ ComponentCache, component_id),
      do: where(query, [c], c.component_id == ^component_id)
  end
end
