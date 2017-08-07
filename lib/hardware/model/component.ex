defmodule Helix.Hardware.Model.Component do

  use Ecto.Schema
  use HELL.ID, field: :component_id, meta: [0x0011]

  import Ecto.Changeset

  alias Ecto.Changeset
  alias HELL.Constant
  alias Helix.Hardware.Model.ComponentSpec
  alias Helix.Hardware.Model.ComponentType
  alias Helix.Hardware.Model.MotherboardSlot

  @type t :: %__MODULE__{
    component_id: id,
    component_type: Constant.t,
    spec_id: ComponentSpec.id,
    component_spec: term,
    slot: term,
    inserted_at: NaiveDateTime.t,
    updated_at: NaiveDateTime.t
  }

  schema "components" do
    field :component_id, ID,
      primary_key: true

    # FK to ComponentType
    field :component_type, Constant

    belongs_to :component_spec, ComponentSpec,
      foreign_key: :spec_id,
      references: :spec_id,
      type: :string

    has_one :slot, MotherboardSlot,
      foreign_key: :link_component_id,
      references: :component_id

    timestamps()
  end

  @spec create_from_spec(ComponentSpec.t) ::
    Changeset.t
  def create_from_spec(cs = %ComponentSpec{}) do
    params = %{
      component_type: cs.component_type,
      spec_id: cs.spec_id
    }

    %__MODULE__{}
    |> cast(params, [:component_type, :spec_id])
    |> validate_required([:component_type, :spec_id])
    |> validate_inclusion(:component_type, ComponentType.possible_types())
  end

  defmodule Query do
    import Ecto.Query

    alias Ecto.Queryable
    alias HELL.Constant
    alias Helix.Hardware.Model.Component

    @spec by_id(Queryable.t, Component.idtb) ::
      Queryable.t
    def by_id(query \\ Component, id),
      do: where(query, [c], c.component_id == ^id)

    @spec from_type_list(Queryable.t, [Constant.t]) ::
      Queryable.t
    def from_type_list(query \\ Component, type_list),
      do: where(query, [c], c.component_type in ^type_list)

    @spec by_type(Queryable.t, Constant.t) ::
      Queryable.t
    def by_type(query \\ Component, type),
      do: where(query, [c], c.component_type == ^type)
  end
end
