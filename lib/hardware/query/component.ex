defmodule Helix.Hardware.Query.Component do

  alias Helix.Hardware.Internal.Component, as: ComponentInternal
  alias Helix.Hardware.Model.Component

  @spec fetch(Component.id) ::
    Component.t
    | nil
  @doc """
  Fetches a component
  """
  defdelegate fetch(component_id),
    to: ComponentInternal

  def get_motherboard(component) do
    ComponentInternal.get_motherboard(component)
  end
end
