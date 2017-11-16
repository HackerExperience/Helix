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

  def create(spec = %Component.Spec{}) do
    spec
    |> Component.create_from_spec()
    |> Repo.insert()
  end
end
