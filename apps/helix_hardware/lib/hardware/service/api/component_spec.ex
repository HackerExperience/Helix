defmodule Helix.Hardware.Service.API.ComponentSpec do

  alias Helix.Hardware.Controller.ComponentSpec, as: ComponentSpecController
  alias Helix.Hardware.Model.ComponentSpec

  @spec create(ComponentSpec.spec) ::
    {:ok, ComponentSpec.t}
    | {:error, Ecto.Changeset.t}
  @doc """
  Creates a component specification from a specification map
  """
  def create(spec_map) do
    ComponentSpecController.create(spec_map)
  end

  @spec fetch(String.t) :: ComponentSpec.t | nil
  @doc """
  Fetches acomponent specification
  """
  def fetch(spec_id) do
    ComponentSpecController.fetch(spec_id)
  end

  @spec find([ComponentSpecController.find_param], meta :: []) ::
    [ComponentSpec.t]
  @doc """
  Search for component specifications

  ## Params

    * `:type` - filters by specification type
  """
  def find(params, meta \\ []) do
    ComponentSpecController.find(params, meta)
  end

  @spec delete(ComponentSpec.t | String.t) :: no_return
  @doc """
  Deletes the component specification

  This function is idempotent
  """
  def delete(component_spec) do
    ComponentSpecController.delete(component_spec)
  end
end
