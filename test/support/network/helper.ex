defmodule Helix.Test.Network.Helper do

  alias Helix.Network.Model.Link
  alias Helix.Network.Model.Net
  alias Helix.Network.Model.Network
  alias Helix.Network.Model.Tunnel
  alias Helix.Network.Query.Network, as: NetworkQuery
  alias Helix.Network.Repo, as: NetworkRepo

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

  @doc """
  Returns all links ([Links.t]) that are part of the tunnel
  """
  def fetch_links(tunnel = %Tunnel{}) do
    tunnel
    |> Link.Query.by_tunnel()
    |> Link.Query.order_by_sequence()
    |> NetworkRepo.all()
  end
end
