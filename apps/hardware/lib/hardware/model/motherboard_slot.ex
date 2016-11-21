defmodule HELM.Hardware.Model.MotherboardSlot do

  use Ecto.Schema
  import Ecto.Changeset

  alias HELL.IPv6
  alias HELM.Hardware.Model.Component, as: MdlComp, warn: false
  alias HELM.Hardware.Model.Motherboard, as: MdlMobo, warn: false
  alias HELM.Hardware.Model.ComponentType, as: MdlCompType, warn: false

  @primary_key {:slot_id, EctoNetwork.INET, autogenerate: false}
  @creation_fields ~w/motherboard_id link_component_type link_component_id slot_internal_id/a
  @update_fields ~w/link_component_id/a

  schema "motherboard_slots" do
    field :slot_internal_id, :integer

    belongs_to :motherboard, MdlMobo,
      foreign_key: :motherboard_id,
      references: :motherboard_id,
      type: EctoNetwork.INET

    belongs_to :component, MdlComp,
      foreign_key: :link_component_id,
      references: :component_id,
      type: EctoNetwork.INET

    belongs_to :component_type, MdlCompType,
      foreign_key: :link_component_type,
      references: :component_type,
      type: :string

    timestamps
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(~w/motherboard_id link_component_type slot_internal_id/a)
    |> put_primary_key()
  end

  def update_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @update_fields)
  end

  defp put_primary_key(changeset) do
    ip = IPv6.generate([0x0003, 0x0002, 0x0000])

    changeset
    |> cast(%{slot_id: ip}, ~w/slot_id/a)
  end
end