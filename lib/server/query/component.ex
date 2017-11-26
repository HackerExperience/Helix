defmodule Helix.Server.Query.Component do

  alias Helix.Server.Model.Component
  alias Helix.Server.Internal.Component, as: ComponentInternal

  @spec fetch(Component.id) ::
    Component.t
    | nil
  def fetch(component_id = %Component.ID{}) do
    component_id
    |> ComponentInternal.fetch()
  end
end
