defmodule Helix.Hardware.Model.MotherboardSlot do

  use Ecto.Schema
  use HELL.ID, field: :slot_id, meta: [0x0011, 0x0002]

  import Ecto.Changeset

  alias Ecto.Changeset
  alias HELL.Constant
  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.Motherboard

  @type t :: %__MODULE__{
    slot_id: id,
    slot_internal_id: integer,
    motherboard_id: Component.id,
    link_component_id: Component.id | nil,
    link_component_type: Constant.t,
    motherboard: term,
    component: term,
    inserted_at: NaiveDateTime.t,
    updated_at: NaiveDateTime.t
  }

  @type creation_params :: %{
    :motherboard_id => Component.id,
    :link_component_type => Constant.t,
    :slot_internal_id => integer,
    optional(:link_component_id) => Component.id
  }
  @type update_params :: %{
    optional(:link_component_id) => Component.id | nil
  }

  @creation_fields ~w/motherboard_id link_component_type slot_internal_id/a
  @required_fields ~w/link_component_type slot_internal_id/a

  schema "motherboard_slots" do
    field :slot_id, ID,
      primary_key: true

    field :slot_internal_id, :integer
    field :motherboard_id, Component.ID
    field :link_component_id, Component.ID
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
    import Ecto.Query

    alias Ecto.Queryable
    alias Helix.Hardware.Model.Component
    alias Helix.Hardware.Model.Motherboard
    alias Helix.Hardware.Model.MotherboardSlot

    @spec by_motherboard(Queryable.t, Component.idtb | Motherboard.t) ::
      Queryable.t
    def by_motherboard(query \\ MotherboardSlot, id)
    def by_motherboard(query, %Motherboard{motherboard_id: id}),
      do: by_motherboard(query, id)
    def by_motherboard(query, id),
      do: where(query, [ms], ms.motherboard_id == ^id)

    @spec by_component(Queryable.t, Component.idtb) ::
      Queryable.t
    def by_component(query \\ MotherboardSlot, id),
      do: where(query, [ms], ms.link_component_id == ^id)

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
