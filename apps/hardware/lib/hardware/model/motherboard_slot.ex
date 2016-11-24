defmodule HELM.Hardware.Model.MotherboardSlot do

  use Ecto.Schema

  alias HELL.PK
  alias HELM.Hardware.Model.Component, as: MdlComp, warn: false
  alias HELM.Hardware.Model.Motherboard, as: MdlMobo, warn: false
  alias HELM.Hardware.Model.ComponentType, as: MdlCompType, warn: false
  import Ecto.Changeset

  @type t :: %__MODULE__{
    slot_id: PK.t,
    slot_internal_id: integer,
    motherboard: MdlMobo.t,
    motherboard_id: PK.t,
    component: MdlComp.t,
    link_component_id: PK.t,
    type: MdlCompType.t,
    link_component_type: String.t,
    inserted_at: Ecto.DateTime.t,
    updated_at: Ecto.DateTime.t
  }

  @type creation_params :: %{
    :motherboard_id => PK.t,
    :link_component_type => String.t,
    :slot_internal_id => integer,
    optional(:link_component_id) => PK.t
  }

  @creation_fields ~w/
    motherboard_id
    link_component_type
    link_component_id
    slot_internal_id/a
  @update_fields ~w/link_component_id/a

  @primary_key false
  schema "motherboard_slots" do
    field :slot_id, EctoNetwork.INET,
      primary_key: true

    field :slot_internal_id, :integer

    belongs_to :motherboard, MdlMobo,
      foreign_key: :motherboard_id,
      references: :motherboard_id,
      type: EctoNetwork.INET
    belongs_to :component, MdlComp,
      foreign_key: :link_component_id,
      references: :component_id,
      type: EctoNetwork.INET
    belongs_to :type, MdlCompType,
      foreign_key: :link_component_type,
      references: :component_type,
      type: :string

    timestamps
  end

  @spec create_changeset(creation_params) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(
      [:motherboard_id, :link_component_type, :slot_internal_id])
    |> put_primary_key()
  end

  @spec update_changeset(t | Ecto.Changeset.t, %{link_component_id: PK.t}) :: Ecto.Changeset.t
  def update_changeset(struct, params) do
    struct
    |> cast(params, @update_fields)
  end

  @spec put_primary_key(Ecto.Changeset.t) :: Ecto.Changeset.t
  defp put_primary_key(changeset) do
    ip = PK.generate([0x0003, 0x0002, 0x0000])

    changeset
    |> cast(%{slot_id: ip}, [:slot_id])
  end
end