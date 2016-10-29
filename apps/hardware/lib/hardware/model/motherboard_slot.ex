defmodule HELM.Hardware.Model.MotherboardSlot do
  use Ecto.Schema
  import Ecto.Changeset

  alias HELL.UUID, as: HUUID
  alias HELM.Hardware.Model.Component, as: MdlComp
  alias HELM.Hardware.Model.Motherboard, as: MdlMobo
  alias HELM.Hardware.Model.ComponentType, as: MdlCompType

  @primary_key {:slot_id, :binary_id, autogenerate: false}
  @creation_fields ~w/motherboard_id link_component_type link_component_id slot_internal_id/a
  @update_fields ~w/link_component_id/a

  schema "motherboard_slots" do
    field :slot_internal_id, :integer

    belongs_to :motherboard, MdlMobo,
      foreign_key: :motherboard_id,
      references: :motherboard_id,
      type: :binary_id

    belongs_to :component, MdlComp,
      foreign_key: :link_component_id,
      references: :component_id,
      type: :binary_id

    belongs_to :component_type, MdlCompType,
      foreign_key: :link_component_type,
      references: :component_type,
      type: :string

    timestamps
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(:motherboard_id)
    |> validate_required(:link_component_type)
    |> validate_required(:slot_internal_id)
    |> put_uid
  end

  def update_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @update_fields)
  end

  defp put_uid(changeset) do
    if changeset.valid?,
      do: put_change(changeset, :slot_id, uuid()),
      else: changeset
  end

  defp uuid,
    do: HUUID.create!("02", meta1: "2")
end