defmodule HELM.Hardware.Motherboard.Slot.Schema do
  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias HELM.Hardware.{Motherboard, Component}
  alias HELM.Hardware.Motherboard.Slot

  @primary_key {:slot_id, :string, autogenerate: false}
  @creation_fields ~w(motherboard_id link_component_type link_component_id slot_internal_id)

  schema "motherboard_slots" do
    field :motherboard_id, :string
    field :link_component_type, :string
    field :link_component_id, :string
    field :slot_internal_id, :integer

    has_one :motherboards, Motherboard.Schema, foreign_key: :motherboard_id, references: :motherboard_id
    has_one :component_types, Component.Type.Schema, foreign_key: :component_type, references: :link_component_type
    has_one :components, Component.Schema, foreign_key: :component_id, references: :link_component_id

    timestamps
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(:motherboard_id)
    |> validate_required(:link_component_type)
    |> validate_required(:link_component_id)
    |> validate_required(:slot_internal_id)
    |> put_uid
  end

  defp put_uid(changeset) do
    if changeset.valid?,
      do: Changeset.put_change(changeset, :slot_id, HELL.ID.generate("SLOT")),
      else: changeset
  end
end
