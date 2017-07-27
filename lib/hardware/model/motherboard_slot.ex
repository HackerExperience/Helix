defmodule Helix.Hardware.Model.MotherboardSlot do

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias HELL.PK
  alias HELL.Constant
  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.Motherboard

  @type id :: PK.t
  @type t :: %__MODULE__{
    slot_id: id,
    slot_internal_id: integer,
    motherboard: Motherboard.t,
    motherboard_id: PK.t,
    component: Component.t,
    link_component_id: PK.t | nil,
    link_component_type: Constant.t,
    inserted_at: NaiveDateTime.t,
    updated_at: NaiveDateTime.t
  }

  @type creation_params :: %{
    :motherboard_id => PK.t,
    :link_component_type => Constant.t,
    :slot_internal_id => integer,
    optional(:link_component_id) => PK.t
  }
  @type update_params :: %{
    optional(:link_component_id) => PK.t | nil
  }

  @creation_fields ~w/motherboard_id link_component_type slot_internal_id/a
  @required_fields ~w/motherboard_id link_component_type slot_internal_id/a

  @primary_key false
  @ecto_autogenerate {:slot_id, {PK, :pk_for, [:hardware_motherboard_slot]}}
  schema "motherboard_slots" do
    field :slot_id, PK,
      primary_key: true

    field :slot_internal_id, :integer
    field :motherboard_id, PK
    field :link_component_id, PK
    field :link_component_type, Constant

    belongs_to :motherboard, Motherboard,
      foreign_key: :motherboard_id,
      references: :motherboard_id,
      define_field: false
    belongs_to :component, Component,
      foreign_key: :link_component_id,
      references: :component_id,
      define_field: false

    timestamps()
  end

  @spec create_changeset(creation_params) ::
    Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> changeset(params)
  end

  @spec update_changeset(t | Changeset.t, update_params) ::
    Changeset.t
  def update_changeset(struct, params) do
    struct
    |> changeset(params)
    |> link_component(params)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [])
    |> validate_required(@required_fields)
    |> unique_constraint(:link_component_id)
  end

  defp link_component(changeset, params) do
    previous = get_field(changeset, :link_component_id)
    changeset = cast(changeset, params, [:link_component_id])
    next = get_change(changeset, :link_component_id)

    # Already has component and is trying to override it
    if previous && next do
      add_error(changeset, :link_component_id, "is already set")
    else
      changeset
    end
  end

  defmodule Query do

    import Ecto.Query, only: [select: 3, where: 3]

    alias Ecto.Queryable
    alias Helix.Hardware.Model.Component
    alias Helix.Hardware.Model.Motherboard
    alias Helix.Hardware.Model.MotherboardSlot

    @spec from_motherboard(Queryable.t, Motherboard.t | Motherboard.id) ::
      Queryable.t
    def from_motherboard(query \\ MotherboardSlot, motherboard_or_id)
    def from_motherboard(query, motherboard = %Motherboard{}),
      do: from_motherboard(query, motherboard.motherboard_id)
    def from_motherboard(query, motherboard_id),
      do: where(query, [ms], ms.motherboard_id == ^motherboard_id)

    @spec by_slot(Queryable.t, MotherboardSlot.t | MotherboardSlot.id) ::
      Queryable.t
    def by_slot(query \\ MotherboardSlot, slot_or_id)
    def by_slot(query, slot = %MotherboardSlot{}),
      do: by_slot(query, slot.slot_id)
    def by_slot(query, slot_id),
      do: where(query, [ms], ms.slot_id == ^slot_id)

    @spec by_component(Queryable.t, Component.t | Component.id) ::
      Queryable.t
    def by_component(query \\ MotherboardSlot, component_or_component_id)
    def by_component(query, component = %Component{}),
      do: by_component(query, component.component_id)
    def by_component(query, component_id),
      do: where(query, [ms], ms.link_component_id == ^component_id)

    @spec only_linked_slots(Queryable.t) ::
      Queryable.t
    def only_linked_slots(query \\ MotherboardSlot),
      do: where(query, [ms], not is_nil(ms.link_component_id))

    @spec select_component_id(Queryable.t) ::
      Queryable.t
    def select_component_id(query \\ MotherboardSlot),
      do: select(query, [ms], ms.link_component_id)
  end
end
