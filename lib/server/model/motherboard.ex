defmodule Helix.Server.Model.Motherboard do

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias HELL.Constant
  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Component
  alias __MODULE__, as: Motherboard

  @type idtb :: Component.idtb | t
  @type idt :: id | t
  @type id :: Component.id
  @type t :: term
  #   motherboard_id: id,
  #   component_spec: term,
  #   component: term,
  #   slots: term,
  #   inserted_at: NaiveDateTime.t,
  #   updated_at: NaiveDateTime.t
  # }

  @type mobo ::
    %__MODULE__{
      motherboard_id: id,
      slots: [{slot_data, component_data}]
    }

  @typep slot_data :: {slot_id, slot_internal_id}
  @typep component_data :: {component_id, component_type} | nil

  # TODO \/ must be defined on their own models
  @typep slot_id :: term
  @typep slot_internal_id :: term
  @typep component_id :: term
  @typep component_type :: term

  @type resources :: term
    # %{
    #   cpu: non_neg_integer,
    #   ram: non_neg_integer,
    #   hdd: non_neg_integer,
    #   net: %{
    #     Network.id =>
    #     %{
    #       uplink: non_neg_integer,
    #       downlink: non_neg_integer
    #     }
    #   }
    # }

  @creation_fields [
    :motherboard_id,
    :slot_id,
    :linked_component_id,
    :linked_component_type
  ]

  @required_fields [
    :motherboard_id,
    :slot_id,
    :linked_component_id,
    :linked_component_type
  ]

  @primary_key false
  schema "motherboards" do
    field :motherboard_id, Component.ID,
      primary_key: true

    field :slot_id, :integer
    field :linked_component_id, Component.ID
    field :linked_component_type, Constant

    belongs_to :linked_component, Component,
      foreign_key: :linked_component_id,
      references: :component_id,
      define_field: false

    belongs_to :mobo_component, Component,
      foreign_key: :motherboard_id,
      references: :component_id,
      define_field: false,
      on_replace: :delete

    has_one :mobo_spec, through: [:mobo_component, :component_spec]

    # Just to make Ecto happy.... so we can use a customized model / %__MODULE__
    field :slots, :map,
      virtual: true,
      default: []
  end

  #initial_components :: [{component = %Component{}, slot_id}])
  @doc """
  The `motherboards` table keeps track of which components are linked to which
  motherboards. The definition of a motherboard, with its spec and any `custom`
  field, exists on the `components` table, defined by `ComponentModel`.

  As such, a motherboard may have no entries here at all - in this case it means
  it's not being used by any other component.

  The `setup/2` function is called right after a Motherboard is being *linked*
  for the first time (not created/bought), so we require that at least one
  component is passed as "initial component". On most cases, we'll always have
  at least one component of each type being passed during the `setup/2` phase.
  """
  def setup(mobo = %Component{type: :mobo}, initial_components) do
    base_changeset = base_changeset(mobo)

    initial_components
    |> Enum.map(fn {component, slot_id} ->
      include_component(base_changeset, slot_id, component)
    end)
  end

  defp base_changeset(%Motherboard{motherboard_id: mobo_id}),
    do: base_changeset(mobo_id)
  defp base_changeset(%Component{type: :mobo, component_id: mobo_id}),
    do: base_changeset(mobo_id)
  defp base_changeset(mobo_id = %Component.ID{}) do
    %__MODULE__{}
    |> cast(%{motherboard_id: mobo_id}, @creation_fields)
  end

  @doc """
  Linking a motherboard will create a *new* changeset. The changeset returned
  here shall be *inserted*, not updated by the caller.
  """
  def link(motherboard = %Motherboard{}, slot_id, component = %Component{}) do
    motherboard
    |> base_changeset()
    |> include_component(slot_id, component)
  end

  defp include_component(changeset, slot_id, component) do
    params =
      %{
        linked_component_id: component.component_id,
        linked_component_type: component.type,
        slot_id: slot_id
      }

    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(@required_fields)
  end

  defmodule Query do
    # TODO2: macro for query/select
    # TODO
  end
end
