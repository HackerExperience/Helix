defmodule Helix.Server.Model.Server do

  use Ecto.Schema

  alias HELL.PK
  alias HELL.Constant
  alias Helix.Server.Model.ServerType

  import Ecto.Changeset

  @type id :: PK.t
  @type t :: %__MODULE__{
    server_id: id,
    poi_id: PK.t,
    motherboard_id: PK.t |  nil,
    inserted_at: NaiveDateTime.t,
    updated_at: NaiveDateTime.t
  }

  @type creation_params :: %{
    :server_type => Constant.t,
    optional(:poi_id) => PK.t | nil,
    optional(:motherboard_id) => PK.t | nil
  }
  @type update_params :: %{
    optional(:poi_id) => PK.t | nil,
    optional(:motherboard_id) => PK.t | nil
  }

  @creation_fields ~w/server_type poi_id motherboard_id/a
  @update_fields ~w/poi_id/a

  @primary_key false
  @ecto_autogenerate {:server_id, {PK, :pk_for, [:server_server]}}
  schema "servers" do
    field :server_id, HELL.PK,
      primary_key: true

    field :poi_id, HELL.PK
    field :motherboard_id, HELL.PK
    field :server_type, Constant

    timestamps()
  end

  @spec create_changeset(creation_params) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(:server_type)
    |> validate_inclusion(:server_type, ServerType.possible_types())
    |> unique_constraint(:motherboard_id)
  end

  @spec update_changeset(t | Ecto.Changeset.t, update_params) :: Ecto.Changeset.t
  def update_changeset(struct, params) do
    struct
    |> cast(params, @update_fields)
    |> unique_constraint(:motherboard_id)
    |> attach_motherboard(params)
  end

  defp attach_motherboard(changeset, params) do
    previous = get_field(changeset, :motherboard_id)
    changeset = cast(changeset, params, [:motherboard_id])
    next = get_change(changeset, :motherboard_id)

    # Already has motherboard and is trying to override it
    if previous && next do
      add_error(changeset, :motherboard_id, "is already set")
    else
      changeset
    end
  end

  defmodule Query do
    alias Helix.Server.Model.Server

    import Ecto.Query, only: [where: 3]

    @spec from_id_list(Ecto.Queryable.t, [HELL.PK.t]) :: Ecto.Queryable.t
    def from_id_list(query \\ Server, id_list),
      do: where(query, [s], s.server_id in ^id_list)

    @spec by_id(Ecto.Queryable.t, HELL.PK.t) :: Ecto.Queryable.t
    def by_id(query \\ Server, server_id),
      do: where(query, [s], s.server_id == ^server_id)

    @spec by_type(Ecto.Queryable.t, String.t) :: Ecto.Queryable.t
    def by_type(query \\ Server, server_type),
      do: where(query, [s], s.server_type == ^server_type)
  end
end