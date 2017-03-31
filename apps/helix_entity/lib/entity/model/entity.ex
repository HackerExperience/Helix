defmodule Helix.Entity.Model.Entity do

  use Ecto.Schema

  alias HELL.PK
  alias HELL.Constant
  alias Helix.Entity.Model.EntityComponent
  alias Helix.Entity.Model.EntityServer
  alias Helix.Entity.Model.EntityType

  import Ecto.Changeset

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

  @spec create_changeset(creation_params) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(@creation_fields)
    |> validate_inclusion(:entity_type, EntityType.possible_types())
  end
end
