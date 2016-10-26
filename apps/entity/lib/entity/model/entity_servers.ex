defmodule HELM.Entity.Model.EntityServers do
  use Ecto.Schema

  import Ecto.Changeset

  alias HELM.Entity.Model.Entities, as: MdlEntities

  @primary_key {:server_id, :string, autogenerate: false}
  @creation_fields ~w/server_id entity_id/a

  schema "entity_servers" do
    belongs_to :entities, MdlEntities,
      foreign_key: :entity_id,
      references: :entity_id,
      type: :string

    timestamps
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(:entity_id)
  end
end