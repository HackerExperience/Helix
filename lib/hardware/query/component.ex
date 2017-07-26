defmodule Helix.Hardware.Query.Component do

  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Query.Component.Origin, as: ComponentQueryOrigin

  @spec fetch(Component.id) ::
    Component.t
    | nil
  @doc """
  Fetches a component
  """
  defdelegate fetch(component_id),
    to: ComponentQueryOrigin

  @spec get_motherboard_id(Component.t | Component.id) ::
    Component.id
    | nil
  defdelegate get_motherboard_id(component),
    to: ComponentQueryOrigin

  defmodule Origin do

    alias Helix.Hardware.Internal.Component, as: ComponentInternal

    defdelegate fetch(component_id),
      to: ComponentInternal

    defdelegate get_motherboard_id(component),
      to: ComponentInternal
  end
end
