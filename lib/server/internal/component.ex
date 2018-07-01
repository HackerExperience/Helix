defmodule Helix.Server.Internal.Component do

  alias Helix.Entity.Model.Entity
  alias Helix.Server.Model.Component
  alias Helix.Server.Model.Motherboard
  alias Helix.Server.Repo

  @spec fetch(Component.id) ::
    Component.t
    | nil
  def fetch(component_id = %Component.ID{}) do
    component =
      component_id
      |> Component.Query.by_id()
      |> Repo.one()

    if component do
      component |> Component.format()
    end
  end

  @spec create(Component.Spec.t, Entity.id) ::
    {:ok, Component.t}
    | {:error, Component.changeset}
  @doc """
  Creates a new component from an existing `Component.Spec`
  """
  def create(spec = %Component.Spec{}, entity_id) do
    spec
    |> Component.create_from_spec(entity_id)
    |> Repo.insert()
  end

  @spec update_custom(Component.t, changes :: map) ::
    {:ok, Component.t}
    | {:error, Component.changeset}
  @doc """
  Updates the `custom` fields of the component
  """
  def update_custom(component = %Component{}, changes) do
    component
    |> Component.update_custom(changes)
    |> Repo.update()
  end

  @spec create_initial_components(Entity.id) ::
    {:ok, [Component.t]}
    | {:error, :internal}
  @doc """
  Creates the initial hardware components, as defined by each Specable @initial.

  Used after a player joins the game and the initial server has to be created.
  """
  def create_initial_components(entity_id) do
    Repo.transaction(fn ->
      result =
        Motherboard.get_initial_components() ++ [:mobo]
        |> Enum.map(fn component_type ->
            component_type
            |> Component.Spec.get_initial()
            |> Component.create_from_spec(entity_id)
            |> Repo.insert()
          end)

      # Checks whether any of the inserts returned `:error`
      case Enum.find(result, fn {status, _} -> status == :error end) do
        nil ->
          Enum.map(result, &(elem(&1, 1)))

        {:error, _} ->
          Repo.rollback(:internal)
      end
    end)
  end

  @spec delete(Component.t) ::
    :ok
  @doc """
  Deletes a component.
  """
  def delete(component = %Component{}) do
    component
    |> Repo.delete()

    :ok
  end
end
