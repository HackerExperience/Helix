defmodule HELM.Entity.Model.EntityServer do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.Changeset
  alias HELM.Entity.Model.Entity, as: MdlEntity, warn: false

  @type create_params :: %{server_id: String.t, entity_id: String.t}

  @primary_key {:server_id, EctoNetwork.INET, autogenerate: false}
  @creation_fields ~w/server_id entity_id/a

  schema "entity_servers" do
    belongs_to :entity, MdlEntity,
      foreign_key: :entity_id,
      references: :entity_id,
      type: EctoNetwork.INET

    timestamps
  end

  @spec create_changeset(params :: create_params) :: Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(:entity_id)
  end
end