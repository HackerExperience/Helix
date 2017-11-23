defmodule Helix.Server.Model.Motherboard do

  use Ecto.Schema

  import Ecto.Changeset
  import HELL.Ecto.Macros

  alias Ecto.Changeset
  alias HELL.Constant
  alias HELL.MapUtils
  alias Helix.Network.Model.Network
  alias Helix.Server.Component.Specable
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
      slots: [{slot_id, Component.t}]
    }

  # TODO \/ must be defined on their own models
  @typep slot_id :: term

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

  def get_resources(motherboard = %Motherboard{}) do
    initial = %{}

    Enum.reduce(motherboard.slots, %{}, fn {_, component}, acc ->
      resource =
        component
        |> Component.get_resources()
        |> Map.from_struct()

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

  def get_initial_components,
    do: [:cpu, :hdd, :nic]

  def has_required_initial_components?(initial_components) do
    initial_components
    |> Enum.reduce(get_initial_components(), fn {component, _}, acc ->
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

    def by_motherboard(query \\ Motherboard, motherboard_id)
    def by_motherboard(query, mobo = %Component{type: :mobo}),
      do: by_motherboard(query, mobo.component_id)
    def by_motherboard(query, motherboard_id) do
      from entries in Motherboard,
        inner_join: component in assoc(entries, :linked_component),
        where: entries.motherboard_id == ^to_string(motherboard_id),
        preload: [:linked_component]
    end

    # def by_component(query, component = %Com) do
    # end
    def by_component(query \\ Motherboard, component_id),
      do: where(query, [m], m.linked_component_id == ^component_id)
  end
end
