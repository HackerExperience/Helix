defmodule HELM.Entity.Model.EntityServer do

  use Ecto.Schema

  alias HELM.Entity.Model.Entity, as: MdlEntity, warn: false
  import Ecto.Changeset

  @type t :: %__MODULE__{
    server_id: MdlServer.id,
    entity_id: MdlEntity.id,
    entity: MdlEntity
  }

  @type creation_params :: %{server_id: MdlServer.id, entity_id: MdlEntity.id}

  @creation_fields ~w/server_id entity_id/a

  @primary_key false
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
    |> validate_required(@creation_fields)
  end
end