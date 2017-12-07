defmodule Helix.Network.Query.Network.Connection do

  alias Helix.Network.Internal.Network, as: NetworkInternal

  defdelegate fetch(network_id, ip),
    to: NetworkInternal.Connection

  defdelegate fetch_by_nic(nic),
    to: NetworkInternal.Connection

  defdelegate get_by_entity(entity_id),
    to: NetworkInternal.Connection
end
