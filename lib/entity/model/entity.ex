defmodule Helix.Entity.Model.Entity do

  use Ecto.Schema
  use HELL.ID, field: :entity_id

  import Ecto.Changeset
  import HELL.Ecto.Macros

  alias Ecto.Changeset
  alias HELL.Constant
  alias Helix.Entity.Model.EntityComponent
  alias Helix.Entity.Model.EntityServer
  alias Helix.Entity.Model.EntityType

  @type type :: :account | :npc | :clan
  @type t :: %__MODULE__{
    entity_id: id,
    entity_type: type,
    components: [EntityComponent.t] | term,
    servers: [EntityServer.t] | term,
    inserted_at: NaiveDateTime.t,
    updated_at: NaiveDateTime.t
  }

  @type creation_params :: %{
    entity_id: term,
    entity_type: type
  }

  @creation_fields [:entity_type]

  schema "entities" do
    field :entity_id, ID,
      primary_key: true

    field :entity_type, Constant

    has_many :components, EntityComponent,
      foreign_key: :entity_id,
      references: :entity_id
    has_many :servers, EntityServer,
      foreign_key: :entity_id,
      references: :entity_id

    timestamps()
  end

  @spec create_changeset(creation_params) ::
    Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(@creation_fields)
    |> validate_inclusion(:entity_type, EntityType.possible_types())
    |> put_change(:entity_id, params.entity_id)
  end

  query do

    alias Helix.Server.Model.Server
    alias Helix.Entity.Model.Entity
    alias Helix.Entity.Model.EntityServer

    @spec by_id(Queryable.t, Entity.idtb) ::
      Queryable.t
    def by_id(query \\ Entity, id),
      do: where(query, [e], e.entity_id == ^id)

    @spec owns_server(Queryable.t, Server.idtb) ::
      Queryable.t
    def owns_server(query \\ Entity, id) do
      query
      |> join(:inner, [e], es in EntityServer, es.entity_id == e.entity_id)
      |> where([e, ..., es], es.server_id == ^id)
    end
  end
end
