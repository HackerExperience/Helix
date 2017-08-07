defmodule Helix.Hardware.Query.Component do

  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Internal.Component, as: ComponentInternal

  @spec fetch(Component.id) ::
    Component.t
    | nil
  @doc """
  Fetches a component
  """
  defdelegate fetch(component_id),
    to: ComponentInternal
end
