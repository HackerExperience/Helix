defmodule Helix.Cache.Model.ComponentCache do

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias HELL.PK
  alias Helix.Hardware.Model.Component
  alias Helix.Cache.Model.Populate.Component, as: ComponentParams
  alias Helix.Cache.Model.Cacheable

  @cache_duration 60 * 60 * 24 * 1000

  @type t :: %__MODULE__{
    component_id: PK.t,
    motherboard_id: PK.t | nil,
    expiration_date: DateTime.t
  }

  @creation_fields ~w/component_id motherboard_id/a

  @primary_key false
  schema "component_cache" do
    field :component_id, PK,
      primary_key: true
    field :motherboard_id, PK

    field :expiration_date, :utc_datetime
  end

  def new(component_id, mobo_id) do
    %__MODULE__{
      component_id: to_string(component_id),
      motherboard_id: to_string(mobo_id)
    }
    |> Cacheable.format_input()
  end

  @spec create_changeset(ComponentParams.t) ::
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
    import Ecto.Query

    alias Ecto.Queryable
    alias Helix.Hardware.Model.Component
    alias Helix.Cache.Model.ComponentCache

    @spec by_component(Queryable.t, Component.idtb) ::
      Queryable.t
    def by_component(query \\ ComponentCache, id),
      do: where(query, [c], c.component_id == ^id)

    @spec filter_expired(Queryable.t) ::
      Queryable.t
    def filter_expired(query),
      do: where(query, [s], s.expiration_date >= fragment("now()"))
  end
end
