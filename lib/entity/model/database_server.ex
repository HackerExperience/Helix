defmodule Helix.Entity.Model.DatabaseServer do

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias HELL.Constant
  alias HELL.IPv4
  alias Helix.Entity.Model.Entity
  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Server

  @type changeset :: %Ecto.Changeset{data: %__MODULE__{}}

  @type t :: %__MODULE__{
    entity_id: Entity.id,
    network_id: Network.id,
    server_id: Server.id,
    server_ip: IPv4.t,
    server_type: Constant.t,
    password: String.t | nil,
    alias: String.t | nil,
    notes: String.t | nil,
    last_update: DateTime.t
  }

  @type creation_params :: %{
    entity_id: Entity.id,
    network_id: Network.id,
    server_id: Server.id,
    server_ip: IPv4.t,
    server_type: Constant.t
  }

  @type update_params :: %{
    optional(:alias) => String.t,
    optional(:notes) => String.t,
    optional(:password) => String.t,
    optional(:last_update) => DateTime.t
  }

  @type server_type ::
    Constant.t

  @creation_fields ~w/entity_id network_id server_ip server_id server_type/a
  @update_fields ~w/alias notes/a

  @required_creation ~w/entity_id network_id server_ip server_id server_type/a

  # Maybe we could provide types for specific NPCs. eg: bank
  @possible_server_types ~w/npc vpc/a

  @alias_max_length 64
  @notes_max_length 1024

  @primary_key false
  schema "database_servers" do
    field :entity_id, Entity.ID,
      primary_key: true
    field :network_id, Network.ID,
      primary_key: true
    field :server_ip, IPv4,
      primary_key: true

    field :server_id, Server.ID

    field :server_type, Constant
    field :password, :string

    field :alias, :string
    field :notes, :string

    field :last_update, :utc_datetime
  end

  @spec create_changeset(creation_params) ::
    Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(@required_creation)
    |> validate_inclusion(:server_type, @possible_server_types)
    |> update_last_update()
  end

  @spec update_changeset(t, map) ::
    Changeset.t
  def update_changeset(struct, params) do
    struct
    |> cast(params, @update_fields)
    |> validate_length(:alias, max: @alias_max_length)
    |> validate_length(:notes, max: @notes_max_length)
    |> update_last_update()
  end

  defp update_last_update(changeset),
    do: put_change(changeset, :last_update, DateTime.utc_now())

  defmodule Query do
    import Ecto.Query

    alias Ecto.Queryable
    alias HELL.IPv4
    alias Helix.Network.Model.Network
    alias Helix.Server.Model.Server
    alias Helix.Entity.Model.DatabaseServer
    alias Helix.Entity.Model.Entity

    @spec by_entity(Queryable.t, Entity.idtb) ::
      Queryable.t
    def by_entity(query \\ DatabaseServer, id),
      do: where(query, [d], d.entity_id == ^id)

    @spec by_nip(Queryable.t, Network.idtb, IPv4.t) ::
      Queryable.t
    def by_nip(query \\ DatabaseServer, network, ip),
      do: where(query, [d], d.network_id == ^network and d.server_ip == ^ip)

    @spec by_server(Queryable.t, Server.idtb) ::
      Queryable.t
    def by_server(query \\ DatabaseServer, id),
      do: where(query, [d], d.server_id == ^id)

    @spec order_by_last_update(Queryable.t) ::
      Queryable.t
    def order_by_last_update(query),
      do: order_by(query, [d], desc: d.last_update)
  end
end
