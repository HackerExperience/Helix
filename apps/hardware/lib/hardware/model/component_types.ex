defmodule HELM.Hardware.Model.ComponentTypes do
  use Ecto.Schema

  import Ecto.Changeset

  alias HELM.Hardware.Model.MotherboardSlots, as: MdlMoboSlots
  alias HELM.Hardware.Model.Components, as: MdlComps
  alias HELM.Hardware.Model.ComponentSpecs, as: MdlCompSpecs

  @primary_key {:component_type, :string, autogenerate: false}
  @creation_fields ~w/component_type/a

  schema "component_types" do
    has_many :slots, MdlMoboSlots,
      foreign_key: :link_component_type,
      references: :component_type

    has_many :components, MdlComps,
      foreign_key: :component_type,
      references: :component_type

    has_many :specs, MdlCompSpecs,
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