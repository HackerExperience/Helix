defmodule Helix.Server.Internal.Motherboard do

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
          result
          |> Enum.map(&(elem(&1, 1)))

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
  Unlinks `component` from `motherboard`.

  Notice we are not *updating* any entries. All `unlink` operations are removing
  data from the `motherboards` table.
  """
  def unlink(motherboard = %Motherboard{}, component = %Component{}) do
    motherboard.motherboard_id
    |> Motherboard.Query.by_component(component.component_id)
    |> Repo.delete_all()

    :ok
  end
end
