defmodule Helix.Network.Helper do

  alias Helix.Network.Query.Network, as: NetworkQuery

  def internet_id,
    do: NetworkQuery.internet().network_id
end
