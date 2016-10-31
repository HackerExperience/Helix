defmodule HELM.Entity.Model.Entity do
  use Ecto.Schema
  alias Ecto.Changeset
  import Ecto.Changeset

  alias HELL.UUID, as: HUUID
  alias HELM.Entity.Model.EntityServer, as: MdlEntityServer
  alias HELM.Entity.Model.EntityType, as: MdlEntityType

  @primary_key {:entity_id, :binary_id, autogenerate: false}
  @creation_fields ~w(entity_type reference_id)a

  schema "entities" do
    field :reference_id, :binary_id

    has_many :servers, MdlEntityServer,
      foreign_key: :entity_id,
      references: :entity_id

    belongs_to :type, MdlEntityType,
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
      do: Changeset.put_change(changeset, :entity_id, uuid()),
      else: changeset
  end

  defp uuid(),
    do: HUUID.create!("bd")
end