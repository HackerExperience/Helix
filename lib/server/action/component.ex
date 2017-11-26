defmodule Helix.Server.Action.Component do

  alias Helix.Server.Internal.Component, as: ComponentInternal

  defdelegate create_initial_components,
    to: ComponentInternal

  defdelegate delete(component),
    to: ComponentInternal
end
