defmodule Helix.Network.Query.Network.Connection do

  alias Helix.Network.Internal.Network, as: NetworkInternal

  defdelegate fetch(network_id, ip),
    to: NetworkInternal.Connection

  defdelegate fetch_by_nic(nic),
    to: NetworkInternal.Connection
end
