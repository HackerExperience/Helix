defmodule Helix.Network.Query.Network do

  alias Helix.Network.Internal.Network, as: NetworkInternal
  alias Helix.Network.Model.Network

  @internet %Network{
    name: "Internet",
    type: :internet,
    network_id: Network.ID.cast!("::")
  }

  @spec fetch(Network.id) ::
    Network.t
    | nil
  @doc """
  Fetches the network entry on the database.
  Hard-coded for the Internet because it's very very common.
  """
  def fetch(%Network.ID{id: {0, 0, 0, 0, 0, 0, 0, 0}}),
    do: internet()
  def fetch(network_id),
    do: NetworkInternal.fetch(network_id)

  @spec internet() ::
    Network.t
  @doc """
  Returns the record for the global network called "The Internet"
  """
  def internet,
    do: @internet
end
