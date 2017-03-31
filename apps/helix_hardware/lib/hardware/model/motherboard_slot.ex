defmodule Helix.Hardware.Model.MotherboardSlot do

  use Ecto.Schema

  alias HELL.PK
  alias HELL.Constant
  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.Motherboard

  import Ecto.Changeset

  @type t :: %__MODULE__{
    slot_id: PK.t,
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
  @accepted_fields ~w/link_component_id/a
  @required_fields ~w/motherboard_id link_component_type slot_internal_id/a

  @primary_key false
  @ecto_autogenerate {:slot_id, {PK, :pk_for, [__MODULE__]}}
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

  @spec create_changeset(creation_params) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> changeset(params)
  end

  @spec update_changeset(t | Ecto.Changeset.t, update_params) :: Ecto.Changeset.t
  def update_changeset(struct, params) do
    changeset(struct, params)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, @accepted_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:link_component_id)
  end

  @spec linked?(t) :: boolean
  def linked?(%__MODULE__{link_component_id: xs}),
    do: !is_nil(xs)

  defmodule Query do

    alias Helix.Hardware.Model.Motherboard
    alias Helix.Hardware.Model.MotherboardSlot

    import Ecto.Query, only: [select: 3, where: 3]

    @spec from_motherboard(Ecto.Queryable.t, Motherboard.t | Motherboard.id) ::
      Ecto.Queryable.t
    def from_motherboard(query \\ MotherboardSlot, motherboard_or_id)
    def from_motherboard(query, motherboard = %Motherboard{}),
      do: from_motherboard(query, motherboard.motherboard_id)
    def from_motherboard(query, motherboard_id),
      do: where(query, [ms], ms.motherboard_id == ^motherboard_id)

    @spec by_id(Ecto.Queryable.t, HELL.PK.t) :: Ecto.Queryable.t
    def by_id(query \\ MotherboardSlot, slot_id) do
      where(query, [ms], ms.slot_id == ^slot_id)
    end

    @spec by_component_id(Ecto.Queryable.t, HELL.PK.t) :: Ecto.Queryable.t
    def by_component_id(query \\ MotherboardSlot, component_id) do
      where(query, [ms], ms.link_component_id == ^component_id)
    end

    @spec only_linked_slots(Ecto.Queryable.t) :: Ecto.Queryable.t
    def only_linked_slots(query \\ MotherboardSlot) do
      where(query, [ms], not is_nil(ms.link_component_id))
    end

    @spec select_component_id(Ecto.Queryable.t) :: Ecto.Queryable.t
    def select_component_id(query \\ MotherboardSlot) do
      select(query, [ms], ms.link_component_id)
    end
  end
end
