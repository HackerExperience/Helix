defmodule Helix.Hardware.Action.ComponentSpec do

  alias Helix.Hardware.Internal.ComponentSpec, as: ComponentSpecInternal
  alias Helix.Hardware.Model.ComponentSpec

  @spec create(ComponentSpec.spec) ::
    {:ok, ComponentSpec.t}
    | {:error, Ecto.Changeset.t}
  @doc """
  Creates a component specification from a specification map
  """
  def create(spec_map) do
    ComponentSpecInternal.create(spec_map)
  end

  @spec delete(ComponentSpec.t | String.t) :: no_return
  @doc """
  Deletes the component specification

  This function is idempotent
  """
  def delete(component_spec) do
    ComponentSpecInternal.delete(component_spec)
  end
end
