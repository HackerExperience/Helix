defmodule Helix.Server.Model.Motherboard do

  use Ecto.Schema

  import Ecto.Changeset
  import HELL.Ecto.Macros

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
    :slot_id,
    :linked_component_id,
    :linked_component_type
  ]

  @required_fields [
    :slot_id,
    :linked_component_id,
    :linked_component_type
  ]

  @primary_key false
  # @primary_key {:motherboard_id, Component.ID, autogenerate: false}
  schema "motherboards" do
    field :motherboard_id, Component.ID,
      primary_key: true

    field :slot_id, Constant
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

    # Just to make Ecto happy.... so we can use a customized model / %__MODULE__
    field :slots, :map,
      virtual: true,
      default: []
  end

  #slots: [{slot_data, component_data}]
  def format([]),
    do: nil
  def format(mobo_entries) do
    slots =
      Enum.reduce(mobo_entries, %{}, fn entry, acc ->
        component = entry.linked_component |> Component.format()

        %{}
        |> Map.put(entry.slot_id, component)
        |> Map.merge(acc)
      end)

    %__MODULE__{
      motherboard_id: List.first(mobo_entries).motherboard_id,
      slots: slots
    }
  end

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
    initial_components
    |> Enum.map(fn {component, slot_id} ->
      changeset =
        %__MODULE__{}
        |> change()
        |> include_component(component, slot_id)

      case check_compatibility(mobo, component, slot_id, []) do
        :ok ->
          changeset
          |> apply_changes()
          |> Map.replace(:motherboard_id, mobo.component_id)

        {:error, reason} ->
          changeset
          |> add_error(:linked_component, reason |> Atom.to_string())
      end
    end)
  end

  def has_required_initial_components?(initial_components) do
    # required = [:cpu, :ram, :hdd, :nic]
    required = [:cpu, :hdd]
    initial_components
    |> Enum.reduce(required, fn {component, _}, acc ->
      acc -- [component.type]
    end)
    |> case do
         [] ->
           true

         _ ->
           false
       end
  end

  @doc """
  Linking a motherboard will create a *new* changeset. The changeset returned
  here shall be *inserted*, not updated by the caller.
  """
  def link(
    motherboard = %Motherboard{},
    mobo_component = %Component{type: :mobo},
    link_component = %Component{},
    slot_id)
  do
    changeset =
      motherboard
      |> change()
      |> include_component(link_component, slot_id)

    compatibility =
      check_compatibility(
        mobo_component, link_component, slot_id, motherboard.slots
      )

    # TODO: Maybe abstract, repeated at `setup/2`
    case compatibility do
      :ok ->
        changeset
        |> apply_changes()
        |> Map.replace(:motherboard_id, motherboard.motherboard_id)

      {:error, reason} ->
        changeset
        |> add_error(:linked_component, reason |> Atom.to_string())
    end
  end

  defp include_component(changeset, component, slot_id) do
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

  defp check_compatibility(
    mobo = %Component{},
    component = %Component{},
    slot_id,
    used_slots)
  do
    Component.Mobo.check_compatibility(
      mobo.spec_id, component.spec_id, slot_id, used_slots
    )
  end

  def get_error(changeset = %Changeset{}) do
    # HACK: I don't want `traverse_errors` and this is the best workaround......
    changeset.errors
    |> List.first()
    |> elem(1)
    |> elem(0)
    |> String.to_existing_atom()
  end

  query do

    def by_motherboard(query \\ Motherboard, motherboard_id) do
      from entries in Motherboard,
        inner_join: component in assoc(entries, :linked_component),
        where: entries.motherboard_id == ^to_string(motherboard_id),
        preload: [:linked_component]
    end

    def by_component(query \\ Motherboard, motherboard_id, component_id) do
      query
      |> where([m], m.motherboard_id == ^motherboard_id)
      |> where([m], m.linked_component_id == ^component_id)
    end
  end
end
