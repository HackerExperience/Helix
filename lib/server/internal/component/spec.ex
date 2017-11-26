defmodule Helix.Server.Internal.Component.Spec do

  alias Helix.Server.Model.Component

  defdelegate fetch(spec_id),
    to: Component.Spec
end
