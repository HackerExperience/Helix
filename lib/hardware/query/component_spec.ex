defmodule Helix.Hardware.Query.ComponentSpec do

  alias Helix.Hardware.Model.ComponentSpec
  alias Helix.Hardware.Internal.ComponentSpec, as: ComponentSpecInternal

  @spec fetch(ComponentSpec.t | ComponentSpec.id) ::
    ComponentSpec.t
    | nil
  @doc """
  Fetches a component specification
  """
  defdelegate fetch(spec),
    to: ComponentSpecInternal
end
