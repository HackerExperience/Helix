defmodule Helix.Server.Model.Server do

  use Ecto.Schema

  import Ecto.Changeset

  alias HELL.PK
  alias HELL.Constant
  alias Helix.Server.Model.ServerType

  @type id :: PK.t
  @type t :: %__MODULE__{
    server_id: id,
    motherboard_id: PK.t |  nil,
    password: String.t,
    inserted_at: NaiveDateTime.t,
    updated_at: NaiveDateTime.t
  }

  @type creation_params :: %{
    :server_type => Constant.t,
    optional(:motherboard_id) => PK.t | nil
  }
  @type update_params :: %{
    optional(:motherboard_id) => PK.t | nil
  }

  @creation_fields ~w/server_type motherboard_id/a

  @primary_key false
  @ecto_autogenerate {:server_id, {PK, :pk_for, [:server_server]}}
  schema "servers" do
    field :server_id, HELL.PK,
      primary_key: true

    field :motherboard_id, HELL.PK
    field :server_type, Constant

    field :password, :string

    timestamps()
  end

  @spec create_changeset(creation_params) ::
    Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(:server_type)
    |> validate_inclusion(:server_type, ServerType.possible_types())
    |> unique_constraint(:motherboard_id)
    |> generate_password()
  end

  @spec update_changeset(t | Ecto.Changeset.t, update_params) ::
    Ecto.Changeset.t
  def update_changeset(struct, params) do
    struct
    |> cast(params, [])
    |> unique_constraint(:motherboard_id)
    |> attach_motherboard(params)
  end

  @spec attach_motherboard(t | Ecto.Changeset.t, map) ::
    Ecto.Changeset.t
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

  @spec generate_password(Ecto.Changeset.t) ::
    Ecto.Changeset.t
  defp generate_password(changeset) do
    # HACK: I don't intend to keep this generation method but it'll be good
    #   enough for now (and is faster than using a proper string generator)
    unique =
      :seconds
      |> System.system_time()
      |> :erlang.+(:erlang.unique_integer())
      |> to_string()

    password =
      :md5
      |> :crypto.hash(unique)
      |> Base.encode16()

    put_change(changeset, :password, password)
  end

  defmodule Query do
    alias Helix.Server.Model.Server

    import Ecto.Query, only: [where: 3]

    @spec by_id(Ecto.Queryable.t, HELL.PK.t) :: Ecto.Queryable.t
    def by_id(query \\ Server, server_id),
      do: where(query, [s], s.server_id == ^server_id)

    @spec by_motherboard(Ecto.Queryable.t, HELL.PK.t) :: Ecto.Queryable.t
    def by_motherboard(query \\ Server, motherboard_id),
      do: where(query, [s], s.motherboard_id == ^motherboard_id)
  end
end
