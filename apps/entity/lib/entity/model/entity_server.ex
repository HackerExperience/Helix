defmodule HELM.Entity.Model.EntityServer do

  use Ecto.Schema
  import Ecto.Changeset

  alias HELM.Entity.Model.Entity, as: MdlEntity, warn: false

  @type t :: %__MODULE__{}
  @type server_id :: String.t
  @type create_params :: %{server_id: server_id, entity_id: MdlEntity.id}

  @primary_key {:server_id, EctoNetwork.INET, autogenerate: false}
  @creation_fields ~w/server_id entity_id/a

  schema "entity_servers" do
    belongs_to :entity, MdlEntity,
      foreign_key: :entity_id,
      references: :entity_id,
      type: EctoNetwork.INET

    timestamps
  end

  @spec create_changeset(create_params) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(:entity_id)
  end
end