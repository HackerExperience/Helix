defmodule Helix.Server.Internal.Component do

  alias Helix.Server.Model.Component
  alias Helix.Server.Repo

  def fetch(component_id = %Component.ID{}) do
    component =
      component_id
      |> Component.Query.by_id()
      |> Repo.one()

    if component do
      component |> Component.format()
    end
  end

  def create(spec = %Component.Spec{}, custom \\ %{}) do
    spec
    |> Component.create_from_spec(custom)
    |> Repo.insert()
  end

  def update_custom(component = %Component{}, changes) do
    component
    |> Component.update_custom(changes)
    |> Repo.update()
  end
end
