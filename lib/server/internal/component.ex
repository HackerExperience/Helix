defmodule Helix.Server.Internal.Component do

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

  @spec create(Component.Spec.t) ::
    {:ok, Component.t}
    | {:error, Component.changeset}
  def create(spec = %Component.Spec{}) do
    spec
    |> Component.create_from_spec()
    |> Repo.insert()
  end

  @spec update_custom(Component.t, changes :: map) ::
    {:ok, Component.t}
    | {:error, Component.changeset}
  def update_custom(component = %Component{}, changes) do
    component
    |> Component.update_custom(changes)
    |> Repo.update()
  end

  @spec create_initial_components() ::
    {:ok, [Component.t]}
    | {:error, :internal}
  def create_initial_components do
    Repo.transaction(fn ->
      result =
        Motherboard.get_initial_components() ++ [:mobo]
        |> Enum.map(fn component_type ->
            component_type
            |> Component.Spec.get_initial()
            |> Component.create_from_spec()
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
  def delete(component = %Component{}) do
    component
    |> Repo.delete()

    :ok
  end
end
