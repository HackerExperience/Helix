defmodule HELM.Entity.Model.Entities do
  use Ecto.Schema

  alias Ecto.Changeset
  import Ecto.Changeset

  alias HELM.Entity.Model.EntityServers, as: MdlEntityServers
  alias HELM.Entity.Model.EntityTypes, as: MdlEntityTypes

  @primary_key {:entity_id, :string, autogenerate: false}
  @creation_fields ~w(entity_type reference_id)a

  schema "entities" do
    field :reference_id, :string

    has_many :servers, MdlEntityServers,
      foreign_key: :entity_id,
      references: :entity_id

    belongs_to :entity_types, MdlEntityTypes,
      foreign_key: :entity_type,
      references: :entity_type,
      type: :string

    timestamps
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> unique_constraint(:reference_id)
    |> put_uuid()
  end

  defp put_uuid(changeset) do
    if changeset.valid?,
      do: Changeset.put_change(changeset, :entity_id, HELL.ID.generate("ENTY")),
      else: changeset
  end
end