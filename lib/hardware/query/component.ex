defmodule Helix.Hardware.Query.Component do

  alias Helix.Hardware.Internal.Component, as: ComponentInternal
  alias Helix.Hardware.Model.Component

  @spec fetch(HELL.PK.t) ::
    Component.t
    | nil
  @doc """
  Fetches a component
  """
  defdelegate fetch(component_id),
    to: ComponentInternal
end
