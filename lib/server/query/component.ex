defmodule Helix.Server.Query.Component do

  alias Helix.Server.Model.Component
  alias Helix.Server.Internal.Component, as: ComponentInternal

  def fetch(component_id = %Component.ID{}) do
    component_id
    |> ComponentInternal.fetch()
  end
end
