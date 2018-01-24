defmodule Helix.Network.Public.Bounce do

  alias Helix.Network.Action.Flow.Bounce, as: BounceFlow

  @doc """
  Creates a new bounce
  """
  defdelegate create(entity_id, name, links, relay),
    to: BounceFlow
end
