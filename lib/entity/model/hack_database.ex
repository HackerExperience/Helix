defmodule Helix.Entity.Model.HackDatabase do

  use Ecto.Schema

  alias HELL.PK
  alias HELL.IPv4

  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @creation_fields ~w/entity_id network_id server_ip server_id server_type/a
  @update_fields ~w/alias notes disabled/a

  @required_creation ~w/entity_id network_id server_ip server_id server_type/a

  # Maybe we could provide types for specific NPCs. eg: bank
  @possible_server_types ~w/npc vpc/

  @alias_max_length 64
  @notes_max_length 1024

  @primary_key false
  schema "hack_database_entries" do
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

  @spec create(PK.t, PK.t, IPv4.t, PK.t, String.t) ::
    Ecto.Changeset.t
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
    Ecto.Changeset.t
  def update(struct, params) do
    struct
    |> cast(params, @update_fields)
    |> validate_length(:alias, max: @alias_max_length)
    |> validate_length(:notes, max: @notes_max_length)
  end
end
