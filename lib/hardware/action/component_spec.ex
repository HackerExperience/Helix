defmodule Helix.Hardware.Action.ComponentSpec do

  alias Helix.Hardware.Internal.ComponentSpec, as: ComponentSpecInternal
  alias Helix.Hardware.Model.ComponentSpec

  @spec create(ComponentSpec.spec) ::
    {:ok, ComponentSpec.t}
    | {:error, Ecto.Changeset.t}
  @doc """
  Creates a component specification from a specification map
  """
  defdelegate create(spec_map),
    to: ComponentSpecInternal

  @spec delete(ComponentSpec.t | String.t) ::
    :ok
  @doc """
  Deletes the component specification

  This function is idempotent
  """
  defdelegate delete(component_spec),
    to: ComponentSpecInternal
end
