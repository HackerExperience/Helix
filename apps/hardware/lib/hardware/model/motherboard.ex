defmodule HELM.Hardware.Model.Motherboard do

  use Ecto.Schema

  alias HELL.PK
  alias HELM.Hardware.Model.Component, as: MdlComp, warn: false
  alias HELM.Hardware.Model.MotherboardSlot, as: MdlMoboSlot, warn: false
  import Ecto.Changeset

  @type t :: %__MODULE__{
    motherboard_id: PK.t,
    slots: [MdlMoboSlot.t],
    inserted_at: Ecto.DateTime.t,
    updated_at: Ecto.DateTime.t
  }

  @type creation_params :: %{motherboard_id: PK.t}

  @creation_fields ~w/motherboard_id/a

  @primary_key false
  schema "motherboards" do
    belongs_to :component, MdlComp,
      foreign_key: :motherboard_id,
      references: :component_id,
      type: EctoNetwork.INET,
      primary_key: true

    has_one :component_spec, through: [:component, :component_spec]

    has_many :slots, MdlMoboSlot,
      foreign_key: :motherboard_id,
      references: :motherboard_id

    timestamps
  end

  @spec create_changeset(creation_params) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(:motherboard_id)
    |> unique_constraint(:motherboard_id)
  end

  @spec parse_motherboard_spec(%{String.t => any}) ::
  [%{
      slot_internal_id: non_neg_integer,
      link_component_type: String.t}]
  def parse_motherboard_spec(component_spec) do
    slots = component_spec.spec["slots"]
    Enum.map(slots, fn {id, spec} ->
      %{
        slot_internal_id: id,
        link_component_type: spec["type"]
      }
    end)
  end
end