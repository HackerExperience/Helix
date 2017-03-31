defmodule Helix.Hardware.Service.API.Component do

  alias Helix.Hardware.Controller.Component, as: ComponentController
  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.ComponentSpec

  @spec create_from_spec(ComponentSpec.t) ::
    {:ok, Component.t}
    | {:error, Ecto.Changeset.t}
  @doc """
  Creates component of given specification
  """
  def create_from_spec(component_spec) do
    ComponentController.create_from_spec(component_spec)
  end

  @spec fetch(HELL.PK.t) :: Component.t | nil
  @doc """
  Fetches a component
  """
  def fetch(component_id) do
    ComponentController.fetch(component_id)
  end

  @spec find([ComponentController.find_param], meta :: []) :: [Component.t]
  @doc """
  Search for components

  ## Params

    * `:id` - search with a list of component id
    * `:type` - filters by `component_type` or `[component_type]`
  """
  def find(params, meta \\ []) do
    ComponentController.find(params, meta)
  end

  @spec delete(Component.t | HELL.PK.t) :: no_return
  @doc """
  Deletes the component

  This function is idempotent
  """
  def delete(component_id) do
    ComponentController.delete(component_id)
  end
end
