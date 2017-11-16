defmodule Helix.Server.Internal.Motherboard do

  alias Helix.Server.Model.Component
  alias Helix.Server.Model.Motherboard
  alias Helix.Server.Repo

  # TODO: Transaction
  def setup(motherboard = %Component{}, [initial_components]) do
    motherboard
    |> Motherboard.setup(initial_components)
    |> Enum.each(&Repo.insert/1)
  end

  @doc """
  Links `component` to the given `motherboard` on `slot_id`.

  Notice we are not *updating* any field. All `link` operations are inserting
  new entries to the `motherboards` table.
  """
  def link(motherboard = %Motherboard{}, slot_id, component = %Component{}) do
    motherboard
    |> Motherboard.link(slot_id, component)
    |> Repo.insert()
  end

  @doc """
  Unlinks `component` from `motherboard`.

  Notice we are not *updating* any entries. All `unlink` operations are removing
  data from the `motherboards` table.
  """
  def unlink(motherboard = %Motherboard{}, component = %Component{}) do
    motherboard
    |> Motherboard.Query.by_motherboard()
    |> Motherboard.Query.by_component(component)
    |> Repo.delete_all()
  end
end
