defmodule HELM.Hardware.Model.ComponentType do

  use Ecto.Schema
  import Ecto.Changeset

  alias HELM.Hardware.Model.MotherboardSlot, as: MdlMoboSlot, warn: false
  alias HELM.Hardware.Model.Component, as: MdlComp, warn: false
  alias HELM.Hardware.Model.ComponentSpec, as: MdlCompSpec, warn: false

  @primary_key {:component_type, :string, autogenerate: false}
  @creation_fields ~w/component_type/a

  schema "component_types" do
    has_many :slots, MdlMoboSlot,
      foreign_key: :link_component_type,
      references: :component_type

    has_many :components, MdlComp,
      foreign_key: :component_type,
      references: :component_type

    has_many :specs, MdlCompSpec,
      foreign_key: :component_type,
      references: :component_type
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(:component_type)
    |> unique_constraint(:component_type)
  end
end