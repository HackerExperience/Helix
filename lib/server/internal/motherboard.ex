defmodule Helix.Server.Internal.Motherboard do

  alias Helix.Server.Internal.Component, as: ComponentInternal
  alias Helix.Server.Model.Component
  alias Helix.Server.Model.Motherboard
  alias Helix.Server.Repo

  def fetch(motherboard_id) do
    motherboard_id
    |> Motherboard.Query.by_motherboard()
    |> Repo.all()
    |> Motherboard.format()
  end

  @doc """
  Returns the total resources that Motherboard has access to.

  Already includes any penalty due to durability or other factors.
  """
  def get_resources(motherboard = %Motherboard{}),
    do: Motherboard.get_resources(motherboard)
  def get_resouces(mobo = %Component{type: :mobo}) do
    mobo.component_id
    |> fetch()
    |> get_resources()
  end

  @doc """
  Fetches the motherboard that `component_id` is currently linked to.
  """
  def fetch_by_component(component_id) do
    component_id
    |> Motherboard.Query.by_component()
    |> Repo.one()
  end

  def get_free_slots(motherboard = %Motherboard{}) do
    motherboard.motherboard_id
    |> ComponentInternal.fetch()
    |> get_free_slots(motherboard)
  end

  def get_free_slots(
    mobo = %Component{type: :mobo},
    motherboard = %Motherboard{})
  do
    Motherboard.get_free_slots(motherboard, mobo.spec_id)
  end

  def get_cpus(motherboard = %Motherboard{}),
    do: get_component(motherboard, :cpu)

  def get_hdds(motherboard = %Motherboard{}),
    do: get_component(motherboard, :hdd)

  def get_nics(motherboard = %Motherboard{}),
    do: get_component(motherboard, :nic)

  def get_rams(motherboard = %Motherboard{}),
    do: get_component(motherboard, :ram)

  defp get_component(motherboard = %Motherboard{}, component_type) do
    Enum.reduce(motherboard.slots, [], fn {_slot_id, component}, acc ->
      if component.type == component_type do
        acc ++ [component]
      else
        acc
      end
    end)
  end

  @doc """
  Creates the initial set of components linked to a motherboard. There must have
  at least 1 of some required components, otherwise the motherboard is deemed
  non-functional before even being set up.
  """
  def setup(motherboard = %Component{}, initial_components) do
    if Motherboard.has_required_initial_components?(initial_components) do
      create_initial_mobo(motherboard, initial_components)
    else
      {:error, :missing_initial_components}
    end
  end

  defp create_initial_mobo(motherboard = %Component{}, initial_components) do
    Repo.transaction(fn ->
      result =
        motherboard
        |> Motherboard.setup(initial_components)
        |> Enum.map(&Repo.insert/1)

      # Checks whether any of the inserts returned `:error`
      case Enum.find(result, fn {status, _} -> status == :error end) do
        nil ->
          entries = Enum.map(result, &(elem(&1, 1)))

          # Below we'll add to the recently created entries their corresponding
          # components, so this is pretty much the same as `Repo.preload` but
          # without doing another join on the DB (since we already have the)
          # components. After doing this "preload", we'll `format/1` the entries
          # and return the expected `Motherboard.mobo`.
          initial_components
          |> Enum.map(fn {component, _slot} -> component end)
          |> Enum.zip(entries)
          |> Enum.reduce([], fn {component, entry}, acc ->
            entry = Map.replace(entry, :linked_component, component)

            acc ++ [entry]
          end)
          |> Motherboard.format()

        {:error, changeset} ->
          changeset
          |> Motherboard.get_error()
          |> Repo.rollback()
      end
    end)
  end

  @doc """
  Links `component` to the given `motherboard` on `slot_id`.

  Notice we are not *updating* any field. All `link` operations are inserting
  new entries to the `motherboards` table.
  """
  def link(
    motherboard = %Motherboard{},
    mobo_component = %Component{type: :mobo},
    link_component = %Component{},
    slot_id)
  do
    result =
      motherboard
      |> Motherboard.link(mobo_component, link_component, slot_id)
      |> Repo.insert()

    case result do
      {:ok, entry} ->
        {:ok, entry}

      {:error, changeset} ->
        {:error, Motherboard.get_error(changeset)}
    end
  end

  @doc """
  `link/3` is a shorthand interface for `link/4` in which we fetch the mobo
  component internally. We still offer `link/4` publicly in case the caller
  already has that information readily available.
  """
  def link(motherboard = %Motherboard{}, component = %Component{}, slot_id) do
    if component.type == :mobo,
      do: raise "You should use `link/4` instead"

    mobo_component = ComponentInternal.fetch(motherboard.motherboard_id)

    link(motherboard, mobo_component, component, slot_id)
  end

  @doc """
  Unlinks `component` from `motherboard`.

  Notice we are not *updating* any entries. All `unlink` operations are removing
  data from the `motherboards` table.
  """
  def unlink(component = %Component{}) do
    component.component_id
    |> Motherboard.Query.by_component()
    |> Repo.delete_all()

    :ok
  end
end
