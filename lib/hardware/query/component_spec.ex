defmodule Helix.Hardware.Query.ComponentSpec do

  alias Helix.Hardware.Internal.ComponentSpec, as: ComponentSpecInternal
  alias Helix.Hardware.Model.ComponentSpec

  @spec fetch(ComponentSpec.id) ::
    ComponentSpec.t
    | nil
  @doc """
  Fetches acomponent specification
  """
  defdelegate fetch(spec_id),
    to: ComponentSpecInternal
end
