defmodule Helix.Test.Network.Helper do

  alias Helix.Network.Model.Net
  alias Helix.Network.Model.Network
  alias Helix.Network.Query.Network, as: NetworkQuery

  alias HELL.TestHelper.Random

  def internet,
    do: NetworkQuery.internet()

  def internet_id,
    do: Network.ID.cast!("::")

  def net,
    do: Net.new(internet_id(), [])

  @doc """
  Generates a Network.id
  """
  def random_id,
    do: Network.ID.generate()
  def id,
    do: random_id()

  @doc """
  Generates a random IP
  """
  def ip,
    do: Random.ipv4()
end
