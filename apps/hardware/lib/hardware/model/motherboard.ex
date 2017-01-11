defmodule Helix.Hardware.Model.Motherboard do

  use Ecto.Schema

  alias HELL.PK
  alias Helix.Hardware.Model.Component, as: MdlComp, warn: false
  alias Helix.Hardware.Model.MotherboardSlot
  import Ecto.Changeset

  @type t :: %__MODULE__{
    motherboard_id: PK.t,
    slots: [MotherboardSlot.t],
    inserted_at: NaiveDateTime.t,
    updated_at: NaiveDateTime.t
  }

  @type creation_params :: %{motherboard_id: PK.t}

  @creation_fields ~w/motherboard_id/a

  @primary_key false
  schema "motherboards" do
    belongs_to :component, MdlComp,
      foreign_key: :motherboard_id,
      references: :component_id,
      type: HELL.PK,
      primary_key: true

    has_one :component_spec, through: [:component, :component_spec]

    has_many :slots, MotherboardSlot,
      foreign_key: :motherboard_id,
      references: :motherboard_id,
      on_delete: :delete_all

    timestamps()
  end

  @spec create_changeset(creation_params) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(:motherboard_id)
    |> unique_constraint(:motherboard_id)
    |> prepare_changes(fn changeset ->
      slots =
        changeset
        |> apply_changes()
        |> changeset.repo.preload(:component_spec)
        |> prepare_slots_for_new_motherboard()

      changeset
      |> cast(%{slots: slots}, [])
      |> cast_assoc(:slots, with: fn _, params ->
        MotherboardSlot.create_changeset(params)
      end)
    end)
  end

  defp prepare_slots_for_new_motherboard(motherboard) do
    case motherboard do
      %__MODULE__{motherboard_id: mid, component_spec: %{spec: %{"slots" => slots}}} ->
        Enum.map(slots, fn {id, spec} ->
          %{
            motherboard_id: mid,
            slot_internal_id: String.to_integer(id),
            link_component_type: spec["type"]
          }
        end)
      %__MODULE__{component_spec: %{spec: _}} ->
        []
    end
  end
end