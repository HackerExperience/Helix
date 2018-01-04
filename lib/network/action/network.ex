defmodule Helix.Network.Action.Network do

  alias Helix.Network.Internal.Network, as: NetworkInternal

  defdelegate create(name, type),
    to: NetworkInternal

  defdelegate delete(network),
    to: NetworkInternal
end
