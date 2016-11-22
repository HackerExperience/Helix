defmodule HELM.Entity.Model.EntityType do

  use Ecto.Schema

  alias HELM.Entity.Model.Entity, as: MdlEntity, warn: false
  import Ecto.Changeset

  @type name :: String.t
  @type t :: %__MODULE__{
    entity_type: name,
    entities: [MdlEntity.t]
  }

  @creation_fields ~w/entity_type/a

  @primary_key {:entity_type, :string, autogenerate: false}
  schema "entity_types" do
    has_many :entities, MdlEntity,
      foreign_key: :entity_type,
      references: :entity_type
  end

  @spec create_changeset(%{entity_type: name}) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(:entity_type)
    |> unique_constraint(:entity_type)
  end
end