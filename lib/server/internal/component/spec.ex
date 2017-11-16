defmodule Helix.Server.Internal.Component.Spec do

  alias Helix.Server.Model.Component
  alias Helix.Server.Component.Specable

  defdelegate fetch(spec_id),
    to: Component.Spec
end
