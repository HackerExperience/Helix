defmodule Helix.Hardware.Model.Motherboard do

  use Ecto.Schema

  alias HELL.PK
  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.ComponentSpec
  alias Helix.Hardware.Model.MotherboardSlot

  import Ecto.Changeset

  @type t :: %__MODULE__{
    motherboard_id: PK.t,
    slots: [MotherboardSlot.t],
    inserted_at: NaiveDateTime.t,
    updated_at: NaiveDateTime.t
  }

  @primary_key false
  schema "motherboards" do
    field :motherboard_id, PK,
      primary_key: true

    belongs_to :component, Component,
      foreign_key: :motherboard_id,
      references: :component_id,
      type: PK,
      define_field: false,
      on_replace: :delete

    has_one :component_spec, through: [:component, :component_spec]

    has_many :slots, MotherboardSlot,
      foreign_key: :motherboard_id,
      references: :motherboard_id,
      on_delete: :delete_all

    timestamps()
  end

  def create_from_spec(cs = %ComponentSpec{spec: spec = %{"slots" => _}}) do
    motherboard_id = PK.generate([0x0003, 0x0001, 0x0000])

    slots = Enum.map(Map.get(spec, "slots"), fn {id, spec} ->
      params = %{
        motherboard_id: motherboard_id,
        slot_internal_id: String.to_integer(id),
        link_component_type: String.downcase(spec["type"])
      }

      MotherboardSlot.create_changeset(params)
    end)

    component = Component.create_from_spec(cs, motherboard_id)

    %__MODULE__{}
    |> change()
    |> put_change(:motherboard_id, motherboard_id)
    |> put_assoc(:slots, slots)
    |> put_assoc(:component, component)
  end

  defmodule Query do

    alias Helix.Hardware.Model.Motherboard

    import Ecto.Query, only: [where: 3]

    def by_id(query \\ Motherboard, motherboard_id) do
      where(query, [m], m.motherboard_id == ^motherboard_id)
    end
  end
end