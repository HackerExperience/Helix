defmodule Helix.Entity.Model.Entity do

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias HELL.PK
  alias HELL.Constant
  alias Helix.Entity.Model.EntityComponent
  alias Helix.Entity.Model.EntityServer
  alias Helix.Entity.Model.EntityType

  @type id :: PK.t
  @type t :: %__MODULE__{
    entity_id: id,
    components: [EntityComponent.t],
    servers: [EntityServer.t],
    entity_type: Constant.t,
    inserted_at: NaiveDateTime.t,
    updated_at: NaiveDateTime.t
  }

  @type creation_params :: %{
    entity_id: id,
    entity_type: Constant.t
  }

  @creation_fields ~w/entity_type entity_id/a

  @primary_key false
  schema "entities" do
    field :entity_id, PK,
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
  end

  defmodule Query do

    import Ecto.Query, only: [where: 3]

    alias Ecto.Queryable
    alias Helix.Entity.Model.Entity

    @spec by_entity(Queryable.t, Entity.t | Entity.id) ::
      Queryable.t
    def by_entity(query \\ Entity, entity_or_entity_id)
    def by_entity(query, %Entity{entity_id: entity_id}),
      do: by_entity(query, entity_id)
    def by_entity(query, entity_id),
      do: where(query, [e], e.entity_id == ^entity_id)
  end
end
