defmodule Helix.Hardware.Query.Component do

  alias Helix.Hardware.Internal.Component, as: ComponentInternal
  alias Helix.Hardware.Model.Component

  @spec fetch(HELL.PK.t) :: Component.t | nil
  @doc """
  Fetches a component
  """
  def fetch(component_id) do
    ComponentInternal.fetch(component_id)
  end

  # TODO: Deprecate this
  @spec find([ComponentInternal.find_param], meta :: []) :: [Component.t]
  @doc """
  Search for components

  ## Params

    * `:id` - search for component ids
    * `:type` - search for components of given component types
  """
  def find(params, meta \\ []) do
    ComponentInternal.find(params, meta)
  end
end
