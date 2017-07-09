defmodule Helix.Entity.Model.EntityServer do

  use Ecto.Schema

  alias Helix.Entity.Model.Entity

  import Ecto.Changeset

  @type t :: %__MODULE__{
    server_id: HELL.PK.t,
    entity_id: Entity.id,
    entity: Entity.t
  }

  @type creation_params :: %{server_id: HELL.PK.t, entity_id: Entity.id}

  @creation_fields ~w/server_id entity_id/a

  @primary_key false
  schema "entity_servers" do
    field :server_id, HELL.PK,
      primary_key: true
    belongs_to :entity, Entity,
      foreign_key: :entity_id,
      references: :entity_id,
      type: HELL.PK,
      primary_key: true
  end

  @spec create_changeset(creation_params) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(@creation_fields)
  end

  defmodule Query do

    alias HELL.PK
    alias Helix.Entity.Model.Entity
    alias Helix.Entity.Model.EntityServer

    import Ecto.Query, only: [where: 3, join: 5]

    def from_entity2(query \\ Entity, entity_id) do
      query
      |> join(:inner, [e], es in EntityServer, es.entity_id == e.entity_id)
      |> where([e, ..., es], es.entity_id == ^entity_id)
    end

    @spec from_entity(Ecto.Queryable.t, Entity.t | Entity.id) ::
      Ecto.Queryable.t
    def from_entity(query \\ EntityServer, entity_or_entity_id)
    def from_entity(query, entity = %Entity{}),
      do: from_entity(query, entity.entity_id)
    def from_entity(query, entity_id),
      do: where(query, [es], es.entity_id == ^entity_id)

    @spec by_server_id(Ecto.Queryable.t, PK.t) :: Ecto.Queryable.t
    def by_server_id(query \\ EntityServer, server_id),
      do: where(query, [es], es.server_id == ^server_id)
  end
end
