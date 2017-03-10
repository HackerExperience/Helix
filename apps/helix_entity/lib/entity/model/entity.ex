defmodule Helix.Entity.Model.Entity do

  use Ecto.Schema

  alias HELL.PK
  alias Helix.Entity.Model.EntityComponent
  alias Helix.Entity.Model.EntityServer
  alias Helix.Entity.Model.EntityType

  import Ecto.Changeset

  @type id :: PK.t
  @type t :: %__MODULE__{
    entity_id: id,
    components: [EntityComponent.t],
    servers: [EntityServer.t],
    entity_type: EntityType.name,
    inserted_at: NaiveDateTime.t,
    updated_at: NaiveDateTime.t
  }

  @type creation_params :: %{
    entity_id: id,
    entity_type: EntityType.name
  }

  @creation_fields ~w/entity_type entity_id/a

  @primary_key false
  schema "entities" do
    field :entity_id, PK,
      primary_key: true

    has_many :components, EntityComponent,
      foreign_key: :entity_id,
      references: :entity_id
    has_many :servers, EntityServer,
      foreign_key: :entity_id,
      references: :entity_id

    # FK to EntityType
    field :entity_type, :string

    timestamps()
  end

  @spec create_changeset(creation_params) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(@creation_fields)
  end
end