defmodule Helix.Entity.Model.EntityComponent do

  use Ecto.Schema

  alias Helix.Entity.Model.Entity

  import Ecto.Changeset

  @type t :: %__MODULE__{
    component_id: HELL.PK.t,
    entity_id: Entity.id,
    entity: Entity.t
  }

  @type creation_params :: %{component_id: HELL.PK.t, entity_id: Entity.id}

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

  defmodule Query do

    alias HELL.PK
    alias Helix.Entity.Model.Entity
    alias Helix.Entity.Model.EntityComponent

    import Ecto.Query, only: [where: 3, select: 3]

    @spec from_entity(Ecto.Queryable.t, Entity.t | Entity.id) ::
      Ecto.Queryable.t
    def from_entity(query \\ EntityComponent, entity_or_entity_id)
    def from_entity(query, entity = %Entity{}),
      do: from_entity(query, entity.entity_id)
    def from_entity(query, entity_id),
      do: where(query, [ec], ec.entity_id == ^entity_id)

    @spec by_component_id(Ecto.Queryable.t, PK.t) :: Ecto.Queryable.t
    def by_component_id(query \\ EntityComponent, component_id),
      do: where(query, [ec], ec.component_id == ^component_id)

    @spec select_component_id(Ecto.Queryable.t) :: Ecto.Queryable.t
    def select_component_id(query \\ EntityComponent),
      do: select(query, [ec], ec.component_id)
  end
end