defmodule Helix.Entity.Model.EntityComponent do

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias Helix.Server.Model.Component
  alias Helix.Entity.Model.Entity

  @type t :: %__MODULE__{
    component_id: Component.id,
    entity_id: Entity.id,
    entity: term
  }

  @type creation_params :: %{
    component_id: Component.idtb,
    entity_id: Entity.idtb
  }

  @creation_fields ~w/component_id entity_id/a

  @primary_key false
  schema "entity_components" do
    field :component_id, Component.ID,
      primary_key: true
    field :entity_id, Entity.ID,
      primary_key: true

    belongs_to :entity, Entity,
      foreign_key: :entity_id,
      references: :entity_id,
      define_field: false,
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
    import Ecto.Query

    alias Ecto.Queryable
    alias Helix.Server.Model.Component
    alias Helix.Entity.Model.Entity
    alias Helix.Entity.Model.EntityComponent

    @spec by_entity(Queryable.t, Entity.idtb) ::
      Queryable.t
    def by_entity(query \\ EntityComponent, id),
      do: where(query, [ec], ec.entity_id == ^id)

    @spec by_component(Queryable.t, Component.idtb) ::
      Ecto.Queryable.t
    def by_component(query \\ EntityComponent, id),
      do: where(query, [ec], ec.component_id == ^id)
  end
end
