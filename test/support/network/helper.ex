defmodule Helix.Test.Network.Helper do

  import Ecto.Changeset

  alias Helix.Network.Model.Bounce
  alias Helix.Network.Model.Connection
  alias Helix.Network.Model.Link
  alias Helix.Network.Model.Network
  alias Helix.Network.Model.Tunnel
  alias Helix.Network.Query.Network, as: NetworkQuery
  alias Helix.Network.Query.Tunnel, as: TunnelQuery
  alias Helix.Network.Repo, as: NetworkRepo

  alias HELL.TestHelper.Random

  def internet,
    do: NetworkQuery.internet()

  def internet_id,
    do: Network.ID.cast!("::")

  @doc """
  Generates a Network.id
  """
  def random_id,
    do: Network.ID.generate()
  def id,
    do: random_id()

  @doc """
  Generates a random connection ID
  """
  def connection_id,
    do: Connection.ID.generate()

  @doc """
  Generates a random bounce ID
  """
  def bounce_id,
    do: Bounce.ID.generate()

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

  @doc """
  Given a connection, modify its (tunnel's) bounce
  """
  def set_bounce(connection = %Connection{}, bounce_id = %Bounce.ID{}) do
    connection
    |> TunnelQuery.fetch_from_connection()
    |> set_bounce(bounce_id)

    TunnelQuery.fetch_connection(connection.connection_id)
  end

  @doc """
  Given a tunnel, modify its bounce
  """
  def set_bounce(tunnel = %Tunnel{}, bounce_id = %Bounce.ID{}) do
    tunnel
    |> change()
    |> force_change(:bounce_id, bounce_id)
    |> NetworkRepo.update()

    TunnelQuery.fetch(tunnel.tunnel_id)
  end
end
