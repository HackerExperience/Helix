defmodule Helix.Server.Model.Server do

  use Ecto.Schema
  use HELL.ID, field: :server_id, meta: [0x0010]

  import Ecto.Changeset
  import HELL.Ecto.Macros

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

  @creation_fields [:type, :motherboard_id, :hostname]
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
    changeset
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> generate_password()
    |> unique_constraint(:motherboard_id)
    |> validate_required(@required_fields)
    |> validate_inclusion(:type, Server.Type.possible_types())
  end

  @spec set_hostname(t, hostname) ::
    changeset
  def set_hostname(server, hostname) do
    server
    |> change()
    |> put_change(:hostname, hostname)
  end

  @spec update_motherboard(t, Motherboard.id | nil) ::
    changeset
  defp update_motherboard(server, mobo_id) do
    server
    |> change()
    |> unique_constraint(:motherboard_id)
    |> put_change(:motherboard_id, mobo_id)
    |> validate_required(@required_fields)
  end

  @spec attach_motherboard(t, Motherboard.id) ::
    changeset
  @doc """
  Assigns `new_mobo_id` to the Server model
  """
  def attach_motherboard(server, new_mobo_id),
    do: update_motherboard(server, new_mobo_id)

  @spec detach_motherboard(t) ::
    changeset
  @doc """
  Removes the `motherboard_id` field from the Server model.
  """
  def detach_motherboard(server),
    do: update_motherboard(server, nil)

  @spec generate_password(changeset) ::
    changeset
  defp generate_password(changeset),
    do: put_change(changeset, :password, Password.generate(:server))

  query do

    alias Helix.Server.Model.Motherboard

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
