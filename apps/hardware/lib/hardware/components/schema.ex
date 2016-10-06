defmodule HELM.Hardware.Component.Schema do
  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias HELM.Hardware.Component

  @primary_key {:component_id, :string, autogenerate: false}
  @creation_fields ~w(component_type spec_id)

  schema "components" do
    field :component_type, :string
    field :spec_id, :string

    has_one :component_types, Component.Type.Schema, foreign_key: :component_type, references: :component_type
    has_one :component_specs, Component.Specs.Schema, foreign_key: :spec_id, references: :spec_id

    timestamps
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(:component_type)
    |> validate_required(:spec_id)
    |> put_uid
  end

  defp put_uid(changeset) do
    if changeset.valid?,
      do: Changeset.put_change(changeset, :component_id, HELL.ID.generate("COMP")),
      else: changeset
  end
end
