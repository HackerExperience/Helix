defmodule Helix.Hardware.Model.MotherboardSlot do

  use Ecto.Schema

  alias HELL.PK
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
    link_component_type: String.t,
    inserted_at: NaiveDateTime.t,
    updated_at: NaiveDateTime.t
  }

  @type creation_params :: %{
    :motherboard_id => PK.t,
    :link_component_type => String.t,
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
  schema "motherboard_slots" do
    field :slot_id, HELL.PK,
      primary_key: true

    field :slot_internal_id, :integer

    belongs_to :motherboard, Motherboard,
      foreign_key: :motherboard_id,
      references: :motherboard_id,
      type: HELL.PK
    belongs_to :component, Component,
      foreign_key: :link_component_id,
      references: :component_id,
      type: HELL.PK

    # FK to ComponentType
    field :link_component_type, :string

    timestamps()
  end

  @spec create_changeset(creation_params) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> put_primary_key()
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

  @spec put_primary_key(Ecto.Changeset.t) :: Ecto.Changeset.t
  defp put_primary_key(changeset) do
    if get_field(changeset, :slot_id) do
      changeset
    else
      pk = PK.generate([0x0003, 0x0002, 0x0000])
      cast(changeset, %{slot_id: pk}, [:slot_id])
    end
  end

  @spec linked?(t) :: boolean
  def linked?(%__MODULE__{link_component_id: xs}),
    do: !is_nil(xs)

  defmodule Query do

    alias Helix.Hardware.Model.Motherboard
    alias Helix.Hardware.Model.MotherboardSlot

    import Ecto.Query, only: [select: 3, where: 3]

    @spec from_motherboard(Ecto.Queryable.t, Motherboard.t) :: Ecto.Queryable.t
    def from_motherboard(query \\ MotherboardSlot, m = %Motherboard{}) do
      by_motherboard_id(query, m.motherboard_id)
    end

    @spec by_id(Ecto.Queryable.t, HELL.PK.t) :: Ecto.Queryable.t
    def by_id(query \\ MotherboardSlot, slot_id) do
      where(query, [ms], ms.slot_id == ^slot_id)
    end

    @spec by_motherboard_id(Ecto.Queryable.t, HELL.PK.t) :: Ecto.Queryable.t
    def by_motherboard_id(query \\ MotherboardSlot, motherboard_id) do
      where(query, [ms], ms.motherboard_id == ^motherboard_id)
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