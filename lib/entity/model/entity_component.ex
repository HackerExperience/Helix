defmodule Helix.Entity.Model.EntityComponent do

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias Helix.Hardware.Model.Component
  alias Helix.Entity.Model.Entity

  @type t :: %__MODULE__{
    component_id: Component.id,
    entity_id: Entity.id,
    entity: Entity.t
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

  @spec create_changeset(creation_params) ::
    Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(@creation_fields)
  end

  defmodule Query do

    import Ecto.Query, only: [where: 3]

    alias Ecto.Queryable
    alias Helix.Hardware.Model.Component
    alias Helix.Entity.Model.Entity
    alias Helix.Entity.Model.EntityComponent

    @spec from_entity(Queryable.t, Entity.t | Entity.id) ::
      Queryable.t
    def from_entity(query \\ EntityComponent, entity_or_entity_id)
    def from_entity(query, %Entity{entity_id: entity_id}),
      do: from_entity(query, entity_id)
    def from_entity(query, entity_id),
      do: where(query, [ec], ec.entity_id == ^entity_id)

    @spec by_component(Queryable.t, Component.t | Component.id) ::
      Ecto.Queryable.t
    def by_component(query \\ EntityComponent, component_or_component_id)
    def by_component(query, %Component{component_id: component_id}),
      do: from_entity(query, component_id)
    def by_component(query, component_id),
      do: where(query, [ec], ec.component_id == ^component_id)
  end
end
