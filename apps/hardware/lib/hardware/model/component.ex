defmodule HELM.Hardware.Model.Component do
  use Ecto.Schema
  import Ecto.Changeset

  alias HELL.UUID, as: HUUID
  alias HELM.Hardware.Model.MotherboardSlot, as: MdlMoboSlot, warn: false
  alias HELM.Hardware.Model.ComponentSpec, as: MdlCompSpec, warn: false

  @primary_key {:component_id, :binary_id, autogenerate: false}
  @creation_fields ~w/component_type spec_id/a

  schema "components" do
    field :component_type, :string

    belongs_to :component_spec, MdlCompSpec,
      foreign_key: :spec_id,
      references: :spec_id,
      type: :binary_id

    has_many :slots, MdlMoboSlot,
      foreign_key: :link_component_id,
      references: :component_id

    timestamps
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(:component_type)
    |> validate_required(:spec_id)
    |> put_uid()
  end

  defp put_uid(changeset) do
    if changeset.valid?,
      do: put_change(changeset, :component_id, uuid()),
      else: changeset
  end

  defp uuid,
    do: HUUID.create!("02", meta1: "1")
end