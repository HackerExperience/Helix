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
  defdelegate create_from_spec(component_spec),
    to: ComponentInternal

  @spec delete(Component.t | Component.id) ::
    :ok
  @doc """
  Deletes the component

  This function is idempotent
  """
  defdelegate delete(component_id),
    to: ComponentInternal
end
