defmodule HELM.Entity.Model.EntityServer do

  use Ecto.Schema
  import Ecto.Changeset

  alias HELM.Entity.Model.Entity, as: MdlEntity, warn: false

  @type t :: %__MODULE__{}
  @type creation_params :: %{server_id: MdlServer.id, entity_id: MdlEntity.id}

  @primary_key false
  @creation_fields ~w/server_id entity_id/a

  schema "entity_servers" do
    field :server_id, EctoNetwork.INET, primary_key: true

    belongs_to :entity, MdlEntity,
      foreign_key: :entity_id,
      references: :entity_id,
      type: EctoNetwork.INET,
      primary_key: true
  end

  @spec create_changeset(creation_params) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(:entity_id)
    |> validate_required(:server_id)
  end
end