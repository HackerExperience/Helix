defmodule Helix.Network.Query.Bounce do

  alias Helix.Entity.Model.Entity
  alias Helix.Network.Internal.Bounce, as: BounceInternal

  defdelegate fetch(bounce_id),
    to: BounceInternal

  def get_by_entity(entity = %Entity{}),
    do: get_by_entity(entity.entity_id)
  def get_by_entity(entity_id = %Entity.ID{}),
    do: BounceInternal.get_by_entity(entity_id)
end
