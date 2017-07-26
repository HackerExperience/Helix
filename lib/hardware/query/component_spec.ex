defmodule Helix.Hardware.Query.ComponentSpec do

  alias Helix.Hardware.Model.ComponentSpec
  alias Helix.Hardware.Query.ComponentSpec.Origin, as: ComponentSpecQueryOrigin

  @spec fetch(ComponentSpec.id) ::
    ComponentSpec.t
    | nil
  @doc """
  Fetches acomponent specification
  """
  defdelegate fetch(spec_id),
    to: ComponentSpecQueryOrigin

  defmodule Origin do

    alias Helix.Hardware.Internal.ComponentSpec, as: ComponentSpecInternal

    defdelegate fetch(spec_id),
      to: ComponentSpecInternal
  end
end
