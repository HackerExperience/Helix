defmodule Helix.Entity.Model.EntityComponent do

  use Ecto.Schema

  alias Helix.Hardware.Model.Component
  alias Helix.Entity.Model.Entity

  import Ecto.Changeset

  @type t :: %__MODULE__{
    component_id: Component.id,
    entity_id: Entity.id,
    entity: Entity
  }

  @type creation_params :: %{component_id: Component.id, entity_id: Entity.id}

  @creation_fields ~w/component_id entity_id/a

  @primary_key false
  schema "entity_components" do
    field :component_id, HELL.PK,
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
end