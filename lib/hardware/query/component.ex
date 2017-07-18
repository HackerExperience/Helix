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

  defdelegate get_motherboard(component),
    to: ComponentQueryOrigin

  defmodule Origin do

    alias Helix.Hardware.Internal.Component, as: ComponentInternal

    def fetch(component_id) do
      ComponentInternal.fetch(component_id)
    end

    def get_motherboard(component) do
      ComponentInternal.get_motherboard(component)
    end
  end
end
