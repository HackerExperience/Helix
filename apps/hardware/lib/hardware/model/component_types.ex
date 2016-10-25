defmodule HELM.Hardware.Component.Type.Schema do
  use Ecto.Schema

  import Ecto.Changeset

  alias HELM.Hardware.Motherboard.Slot.Schema, as: MoboSlotSchema
  alias HELM.Hardware.Component.Schema, as: CompSchema
  alias HELM.Hardware.Component.Spec.Schema, as: CompSpecSchema

  @primary_key {:component_type, :string, autogenerate: false}
  @creation_fields ~w/component_type/a

  schema "component_types" do
    has_many :slots, MoboSlotSchema,
      foreign_key: :link_component_type,
      references: :component_type

    has_many :components, CompSchema,
      foreign_key: :component_type,
      references: :component_type

    has_many :specs, CompSpecSchema,
      foreign_key: :component_type,
      references: :component_type

    timestamps
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(:component_type)
  end
end
