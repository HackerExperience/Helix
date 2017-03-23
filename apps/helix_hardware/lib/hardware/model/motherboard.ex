defmodule Helix.Hardware.Model.Motherboard do

  use Ecto.Schema

  alias HELL.PK
  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.ComponentSpec
  alias Helix.Hardware.Model.MotherboardSlot

  import Ecto.Changeset

  @behaviour Helix.Hardware.Model.ComponentSpec

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

  def create_from_spec(cs = %ComponentSpec{spec: %{"slots" => slots}}) do
    motherboard_id = PK.pk_for(__MODULE__)

    slots = Enum.map(slots, fn {id, spec} ->
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

  @spec validate_spec(%{slots: %{optional(String.t) => map}}) :: Ecto.Changeset.t
  @doc false
  def validate_spec(params) do
    slot_data = %{
      slot_id: nil,
      type: nil,
      limit: nil
    }
    slot_types = %{
      slot_id: :string,
      type: :string,
      limit: :integer
    }

    mobo_data = %{
      slots: nil
    }
    mobo_type = %{
      slots: :map
    }

    changeset = cast({mobo_data, mobo_type}, params, [:slots])

    {slots, errors} = Enum.map_reduce(get_change(changeset, :slots), [], fn
      {i, params}, acc ->
        changeset =
          {slot_data, slot_types}
          |> cast(params, [:slot_id, :type, :limit])
          |> put_change(:slot_id, i)
          |> validate_required([:slot_id, :type])
          |> validate_number(:limit, greater_than_or_equal_to: 1)
          |> validate_format(:slot_id, ~r/^[0-9]{1,3}$/)
          |> validate_inclusion(:type, ComponentSpec.valid_spec_types())

        # REVIEW: maybe normalize it like a struct (ie: leave nil fields) and
        #   just ensure that models properly know how not to shoot themselves
        #   in the foot
        {slot_id, slot} =
          changeset
          |> apply_changes()
          |> Enum.reject(fn {_, v} -> is_nil(v) end)
          |> Keyword.pop(:slot_id)

        acc = if changeset.valid? do
          acc
        else
          [{slot_id, changeset.errors}| acc]
        end

        {{slot_id, :maps.from_list(slot)}, acc}
    end)

    changeset =
      changeset
      |> put_change(:slots, :maps.from_list(slots))
      |> validate_change(:slots, fn :slots, slots ->
        if map_size(slots) > 0 do
          []
        else
          [slots: "cannot be blank"]
        end
      end)

    if Enum.empty?(errors) do
      changeset
    else
      add_error(changeset, :slots, "is invalid", errors)
    end
  end

  defmodule Query do

    alias Helix.Hardware.Model.Motherboard

    import Ecto.Query, only: [where: 3]

    def by_id(query \\ Motherboard, motherboard_id) do
      where(query, [m], m.motherboard_id == ^motherboard_id)
    end
  end
end
