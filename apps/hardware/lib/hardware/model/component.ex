defmodule HELM.Hardware.Model.Component do
  use Ecto.Schema
  import Ecto.Changeset

  alias HELL.IPv6
  alias HELM.Hardware.Model.MotherboardSlot, as: MdlMoboSlot, warn: false
  alias HELM.Hardware.Model.ComponentSpec, as: MdlCompSpec, warn: false

  @primary_key {:component_id, EctoNetwork.INET, autogenerate: false}
  @creation_fields ~w/component_type spec_id/a

  schema "components" do
    field :component_type, :string

    belongs_to :component_spec, MdlCompSpec,
      foreign_key: :spec_id,
      references: :spec_id,
      type: EctoNetwork.INET

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
    |> put_primary_key()
  end

  defp put_primary_key(changeset) do
    if changeset.valid? do
      ip = IPv6.generate([0x0003, 0x0001, 0x0000])

      changeset
      |> cast(%{component_id: ip}, ~w(component_id))
    else
      changeset
    end
  end
end