defmodule HELM.Hardware.Model.ComponentType do

  use Ecto.Schema

  alias HELM.Hardware.Model.MotherboardSlot, as: MdlMoboSlot, warn: false
  alias HELM.Hardware.Model.Component, as: MdlComp, warn: false
  alias HELM.Hardware.Model.ComponentSpec, as: MdlCompSpec, warn: false
  import Ecto.Changeset

  @type t :: %__MODULE__{
    component_type: String.t,
    slots: [MdlMoboSlot.t],
    components: [MdlComp.t],
    specs: [MdlCompSpec.t]
  }

  @creation_fields ~w/component_type/a

  @primary_key {:component_type, :string, autogenerate: false}
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

  @spec create_changeset(%{component_type: String.t}) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(:component_type)
    |> unique_constraint(:component_type)
  end
end