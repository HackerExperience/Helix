defmodule Helix.Server.Model.Motherboard do
  @moduledoc """
  This model defines all components that are linked to a motherboard.

  Notice that a motherboard itself is a Component! As such, it is saved and
  defined at the `Component` model/table. The `Motherboard` model references the
  motherboard defined at `Component`, and each linked component is also
  referenced on the `Component` table.

  So, while `Component` holds the hardware component information, `Motherboard`
  tells us which components are linked to which motherboards.
  """

  use Ecto.Schema

  import Ecto.Changeset
  import HELL.Ecto.Macros

  alias Ecto.Changeset
  alias HELL.Constant
  alias HELL.MapUtils
  alias Helix.Server.Component.Specable
  alias Helix.Server.Model.Component
  alias __MODULE__, as: Motherboard

  @type idtb :: Component.idtb | t
  @type idt :: id | t
  @type id :: Component.id
  @type t ::
    %__MODULE__{
      motherboard_id: id,
      slots: [slot]
    }

  @type changeset :: %Changeset{data: %__MODULE__{}}

  @type resources ::
    %{
      cpu: Component.CPU.custom,
      hdd: Component.HDD.custom,
      ram: Component.RAM.custom,
      net: Component.NIC.custom
    }

  @type initial_components :: [{Component.pluggable, slot_id}]
  @type required_components :: [Constant.t]

  @type slot_id :: Component.Mobo.slot_id
  @type slot :: {slot_id, Component.t}
  @type free_slots :: %{Component.type => [slot_id]}

  @type error ::
    :wrong_slot_type
    | :bad_slot
    | :slot_in_use

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

  @spec format([t]) ::
    t
    | nil
  @doc """
  `format/1` gets the fetch result (i.e. a list of all components that are
  linked to the specified motherboard) and aggregates it into a record, mapping
  each linked component to the underlying motherboard slot_id.
  """
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

  @spec get_resources(t) ::
    resources
  @doc """
  Returns the total resources of the Motherboard. In order to do so, it iterates
  through every component linked to the motherboard and aggregates the sum.
  """
  def get_resources(motherboard = %Motherboard{}) do
    Enum.reduce(motherboard.slots, %{}, fn {_, component}, acc ->
      resource = Component.get_resources(component)

      {key, merge_fun} =
        if component.type == :nic do
          {:net, fn a, b -> Map.merge(a, b, fn _, vA, vB -> vA + vB end) end}
        else
          {component.type, fn a, b -> a + b end}
        end

      %{}
      |> Map.put(key, resource)
      |> MapUtils.naive_deep_merge(acc, &merge_fun.(&1, &2))
    end)
  end

  @spec setup(Component.mobo, initial_components) ::
    [t | changeset]
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
    |> Enum.reject(fn {component, _} -> component.type == :mobo end)
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

  @spec get_initial_components() ::
    required_components
  @doc """
  Returns a list of components that an initial player motherboard must have.
  """
  def get_initial_components,
    do: [:cpu, :hdd, :nic, :ram]

  @spec has_required_initial_components?(initial_components) ::
    boolean
  @doc """
  Checks whether a player's initial motherboard has all the required components.
  """
  def has_required_initial_components?(initial_components) do
    missing_components =
      initial_components
      |> Enum.reduce(get_initial_components(), fn {component, _}, acc ->
        acc -- [component.type]
      end)

    missing_components == []
  end

  @spec link(t, Component.mobo, Component.pluggable, Component.Mobo.slot_id) ::
    term
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

  @spec get_free_slots(t, Component.Spec.mobo) ::
    free_slots
  @doc """
  Returns a list of all slots that the motherboard support and are not in use by
  any component. It maps each available slot to the underlying slot type, so
  callers/users of this function have a nicer interface.
  """
  def get_free_slots(motherboard = %Motherboard{}, spec_id) do
    slots =
      spec_id
      |> Specable.fetch()
      |> Map.fetch!(:slots)

    available_map =
      Enum.reduce(motherboard.slots, slots, fn {slot_id, _component}, acc ->
        {slot_type, real_id} = Component.Mobo.split_slot_id(slot_id)

        new_sub_type =
          acc
          |> Map.fetch!(slot_type)
          |> Map.delete(real_id)

        acc
        |> Map.replace(slot_type, new_sub_type)
      end)

    # Now we'll convert the available map into an API-friendly list
    available_map
    |> Enum.reduce(%{}, fn {slot_type, available}, acc ->
      available_slots =
        Enum.reduce(available, [], fn {real_id, _}, acc ->
          available_id =
            to_string(slot_type) <> "_" <> to_string(real_id)
            |> String.to_atom()

          acc ++ [available_id]
        end)

      %{}
      |> Map.put(slot_type, available_slots)
      |> Map.merge(acc)
    end)
  end

  @spec include_component(changeset, Component.t, Component.Mobo.slot_id) ::
    changeset
  defp include_component(changeset, component, slot_id) do
    params =
      %{
        linked_component_id: component.component_id,
        linked_component_type: component.type,
        slot_id: slot_id
      }

    changeset
    |> cast(params, @creation_fields)
    |> validate_required(@required_fields)
  end

  @spec get_error(changeset) ::
    error
  @doc """
  Returns one of the errors that happened on the Changeset during any operation.
  """
  def get_error(changeset = %Changeset{}) do
    # HACK: I don't want `traverse_errors` and this is the best workaround......
    changeset.errors
    |> List.first()
    |> elem(1)
    |> elem(0)
    |> String.to_existing_atom()
  end

  @spec check_compatibility(
    Component.mobo, Component.t, Component.Mobo.slot_id, [slot])
  ::
    :ok
    | {:error, :wrong_slot_type}
    | {:error, :slot_in_use}
    | {:error, :bad_slot}
  def check_compatibility(
    mobo = %Component{},
    component = %Component{},
    slot_id,
    used_slots)
  do
    Component.Mobo.check_compatibility(
      mobo.spec_id, component.spec_id, slot_id, used_slots
    )
  end

  query do

    alias Helix.Server.Model.Component

    @spec by_motherboard(Queryable.t, Motherboard.idt, [eager: boolean]) ::
      Queryable.t
    def by_motherboard(query \\ Motherboard, motherboard_id, eager?)
    def by_motherboard(query, mobo = %Component{type: :mobo}, eager?),
      do: by_motherboard(query, mobo.component_id, eager?)
    def by_motherboard(query, motherboard_id, eager: false),
      do: where(query, [m], m.motherboard_id == ^motherboard_id)
    def by_motherboard(query, motherboard_id, _) do
      from entries in query,
        inner_join: component in assoc(entries, :linked_component),
        where: entries.motherboard_id == ^to_string(motherboard_id),
        preload: [:linked_component]
    end

    @spec by_component(Queryable.t, Component.id, [eager: boolean]) ::
      Queryable.t
    @doc """
    SELECT m.*
    FROM motherboards m
    INNER JOIN (
      SELECT motherboard_id
      FROM motherboards
      WHERE linked_component_id = $component_id) entry
    ON entry.motherboard_id = m.motherboard_id
    """
    def by_component(query \\ Motherboard, component_id, eager?)
    def by_component(query, component_id, eager: false),
      do: where(query, [m], m.linked_component_id == ^component_id)

    def by_component(query, component_id, eager: true) do
      q1 =
        from entry in query,
        where: entry.linked_component_id == ^component_id,
        select: [:motherboard_id]

      from m in Motherboard,
        inner_join: entry in subquery(q1),
        on: entry.motherboard_id == m.motherboard_id,
        select: m,
        preload: [:linked_component]
    end
  end
end
