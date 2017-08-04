defmodule Helix.Server.Model.Server do

  use Ecto.Schema
  use HELL.ID, field: :server_id, meta: [0x0010]

  import Ecto.Changeset

  alias Ecto.Changeset
  alias HELL.Constant
  alias Helix.Hardware.Model.Component
  alias Helix.Server.Model.ServerType

  @type t :: %__MODULE__{
    server_id: id,
    motherboard_id: Component.id |  nil,
    password: String.t,
    inserted_at: NaiveDateTime.t,
    updated_at: NaiveDateTime.t
  }

  @type creation_params :: %{
    :server_type => Constant.t,
    optional(:motherboard_id) => Component.idtb | nil
  }
  @type update_params :: %{
    optional(:motherboard_id) => Component.idtb | nil
  }

  @creation_fields ~w/server_type motherboard_id/a

  schema "servers" do
    field :server_id, ID,
      primary_key: true

    field :motherboard_id, Component.ID
    field :server_type, Constant

    field :password, :string

    timestamps()
  end

  @spec create_changeset(creation_params) ::
    Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(:server_type)
    |> validate_inclusion(:server_type, ServerType.possible_types())
    |> unique_constraint(:motherboard_id)
    |> generate_password()
  end

  @spec update_changeset(t | Changeset.t, update_params) ::
    Changeset.t
  def update_changeset(struct, params) do
    struct
    |> cast(params, [])
    |> unique_constraint(:motherboard_id)
    |> attach_motherboard(params)
  end

  @spec detach_motherboard(t | Changeset.t) ::
    Changeset.t
  def detach_motherboard(struct),
    do: update_changeset(struct, %{motherboard_id: nil})

  @spec attach_motherboard(t | Changeset.t, map) ::
    Changeset.t
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

  @spec generate_password(Changeset.t) ::
    Changeset.t
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
    import Ecto.Query

    alias Ecto.Queryable
    alias Helix.Hardware.Model.Component
    alias Helix.Server.Model.Server

    @spec by_id(Queryable.t, Server.idtb) ::
      Queryable.t
    def by_id(query \\ Server, id),
      do: where(query, [s], s.server_id == ^id)

    @spec by_motherboard(Queryable.t, Component.idtb) ::
      Queryable.t
    def by_motherboard(query \\ Server, id),
      do: where(query, [s], s.motherboard_id == ^id)
  end
end
