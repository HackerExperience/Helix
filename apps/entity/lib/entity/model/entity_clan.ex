defmodule Helix.Entity.Model.EntityClan do

  use Ecto.Schema

  alias HELM.Entity.Model.Entity, warn: false
  import Ecto.Changeset

  @type t :: %__MODULE__{
    entity_id: Entity.id,
    entity: Entity
  }

  @type creation_params :: %{entity_id: Entity.id}

  @creation_fields ~w/entity_id/a

  @primary_key false
  schema "entity_clans" do
    belongs_to :entity, Entity,
      foreign_key: :entity_id,
      references: :entity_id,
      type: EctoNetwork.INET,
      primary_key: true
  end

  @spec create_changeset(creation_params) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required([:entity_id])
  end
end