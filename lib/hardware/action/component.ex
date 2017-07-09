defmodule Helix.Hardware.Action.Component do

  alias Helix.Hardware.Internal.Component, as: ComponentInternal
  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.ComponentSpec

  @spec create_from_spec(ComponentSpec.t) ::
    {:ok, Component.t}
    | {:error, Ecto.Changeset.t}
  @doc """
  Creates component of given specification
  """
  def create_from_spec(component_spec) do
    ComponentInternal.create_from_spec(component_spec)
  end

  @spec delete(Component.t | HELL.PK.t) :: :ok
  @doc """
  Deletes the component

  This function is idempotent
  """
  def delete(component_id) do
    ComponentInternal.delete(component_id)
  end
end
