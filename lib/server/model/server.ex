defmodule Helix.Server.Model.Server do

  use Ecto.Schema
  use HELL.ID, field: :server_id, meta: [0x0010]

  import Ecto.Changeset

  alias Ecto.Changeset
  alias HELL.Constant
  alias HELL.Password
  alias Helix.Server.Model.Component
  alias Helix.Server.Model.Motherboard
  alias __MODULE__, as: Server

  @type t :: %__MODULE__{
    server_id: id,
    type: type,
    motherboard_id: Component.id |  nil,
    password: password,
    hostname: hostname
  }

  @type changeset :: %Changeset{data: %__MODULE__{}}

  @type hostname :: String.t
  @type name :: hostname
  @type type :: Server.Type.type
  @type password :: String.t

  @type resources :: Motherboard.resources

  @type creation_params :: %{
    :type => Constant.t,
    optional(:motherboard_id) => Motherboard.id | nil
  }

  @type update_params :: %{
    optional(:motherboard_id) => Motherboard.id | nil
  }

  @creation_fields [:type, :motherboard_id]
  @required_fields [:type, :password]

  schema "servers" do
    field :server_id, ID,
      primary_key: true

    field :motherboard_id, Component.ID
    field :type, Constant

    field :hostname, :string,
      default: "transltr"
    field :password, :string
  end

  @spec create_changeset(creation_params) ::
    Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> generate_password()
    |> unique_constraint(:motherboard_id)
    |> validate_required(@required_fields)
    |> validate_inclusion(:type, Server.Type.possible_types())
  end

  @spec update_changeset(t | Changeset.t, update_params) ::
    Changeset.t
  def update_changeset(struct, params) do
    struct
    |> cast(params, [])
    |> unique_constraint(:motherboard_id)
    |> attach_motherboard(params)
    |> validate_required(@required_fields)
  end

  @spec set_hostname(t, hostname) ::
    changeset
  def set_hostname(server, hostname) do
    server
    |> change()
    |> put_change(:hostname, hostname)
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
  defp generate_password(changeset),
    do: put_change(changeset, :password, Password.generate(:server))

  defmodule Query do

    import Ecto.Query

    alias Ecto.Queryable
    alias Helix.Server.Model.Motherboard
    alias Helix.Server.Model.Server

    @spec by_id(Queryable.t, Server.idtb) ::
      Queryable.t
    def by_id(query \\ Server, id),
      do: where(query, [s], s.server_id == ^id)

    @spec by_motherboard(Queryable.t, Motherboard.idt) ::
      Queryable.t
    def by_motherboard(query \\ Server, id)
    def by_motherboard(query, %Motherboard{motherboard_id: id}),
      do: by_motherboard(query, id)
    def by_motherboard(query, id),
      do: where(query, [s], s.motherboard_id == ^id)
  end
end
