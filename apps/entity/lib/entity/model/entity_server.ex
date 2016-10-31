defmodule HELM.Entity.Model.EntityServer do
  use Ecto.Schema

  import Ecto.Changeset

  alias HELM.Entity.Model.Entity, as: MdlEntity, warn: false

  @primary_key {:server_id, :binary_id, autogenerate: false}
  @creation_fields ~w/server_id entity_id/a

  schema "entity_servers" do
    belongs_to :entity, MdlEntity,
      foreign_key: :entity_id,
      references: :entity_id,
      type: :binary_id

    timestamps
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(:entity_id)
  end
end