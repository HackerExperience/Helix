defmodule Helix.Entity.Model.Database do

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias HELL.PK
  alias HELL.IPv4
  alias Helix.Entity.Model.Entity
  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Server

  @type t :: %__MODULE__{}

  @creation_fields ~w/entity_id network_id server_ip server_id server_type/a
  @update_fields ~w/alias notes disabled/a

  @required_creation ~w/entity_id network_id server_ip server_id server_type/a

  # Maybe we could provide types for specific NPCs. eg: bank
  @possible_server_types ~w/npc vpc/

  @alias_max_length 64
  @notes_max_length 1024

  @primary_key false
  schema "database_entries" do
    field :entity_id, PK,
      primary_key: true
    field :network_id, PK,
      primary_key: true
    field :server_ip, IPv4,
      primary_key: true

    field :server_id, PK

    field :server_type, :string
    field :password, :string

    field :alias, :string
    field :notes, :string

    field :disabled, :boolean,
      default: false

    timestamps()
  end

  @spec create(Entity.t | Entity.id, Network.t | Network.id, IPv4.t, Server.t | Server.id, String.t) ::
    Changeset.t
  def create(%Entity{entity_id: entity}, network, ip, server, type),
    do: create(entity, network, ip, server, type)
  def create(entity, %Network{network_id: network}, ip, server, type),
    do: create(entity, network, ip, server, type)
  def create(entity, network, ip, %Server{server_id: server}, type),
    do: create(entity, network, ip, server, type)
  def create(entity_id, network_id, ip, server_id, server_type) do
    params = %{
      entity_id: entity_id,
      network_id: network_id,
      server_ip: ip,
      server_id: server_id,
      server_type: server_type
    }

    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(@required_creation)
    |> validate_inclusion(:server_type, @possible_server_types)
  end

  @spec update(t, map) ::
    Changeset.t
  def update(struct, params) do
    struct
    |> cast(params, @update_fields)
    |> validate_length(:alias, max: @alias_max_length)
    |> validate_length(:notes, max: @notes_max_length)
  end

  defmodule Query do

    import Ecto.Query

    alias Ecto.Queryable
    alias HELL.IPv4
    alias Helix.Network.Model.Network
    alias Helix.Server.Model.Server
    alias Helix.Entity.Model.Database
    alias Helix.Entity.Model.Entity

    @spec by_entity(Queryable.t, Entity.t | Entity.id) ::
      Queryable.t
    def by_entity(query \\ Database, entity_or_id)
    def by_entity(query, %Entity{entity_id: id}),
      do: by_entity(query, id)
    def by_entity(query, id),
      do: where(query, [d], d.entity_id == ^id)

    @spec by_network(Queryable.t, Network.t | Network.id) ::
      Queryable.t
    def by_network(query \\ Database, network_or_id)
    def by_network(query, %Network{network_id: id}),
      do: by_network(query, id)
    def by_network(query, id),
      do: where(query, [d], d.network_id == ^id)

    @spec by_server(Queryable.t, Server.t | Server.id) ::
      Queryable.t
    def by_server(query \\ Database, server_or_id)
    def by_server(query, %Server{server_id: id}),
      do: by_server(query, id)
    def by_server(query, id),
      do: where(query, [d], d.server_id == ^id)

    @spec by_ip(Queryable.t, IPv4.t) ::
      Queryable.t
    def by_ip(query \\ Database, ip),
      do: where(query, [d], d.server_ip == ^ip)

    @spec order_by_newest_on_network(Queryable.t) ::
      Queryable.t
    def order_by_newest_on_network(query),
      do: order_by(query, asc: :network_id, asc: :inserted_at)
  end
end
