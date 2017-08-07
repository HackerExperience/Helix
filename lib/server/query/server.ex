defmodule Helix.Server.Query.Server do

  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Hardware.Model.Motherboard
  alias Helix.Hardware.Model.NetworkConnection
  alias Helix.Network.Model.Network
  alias Helix.Server.Internal.Server, as: ServerInternal
  alias Helix.Server.Model.Server

  @spec fetch(Server.id) ::
    Server.t
    | nil
  @doc """
  Fetches a server
  """
  defdelegate fetch(server_id),
    to: ServerInternal

  @spec fetch_by_motherboard(Motherboard.t | Motherboard.id) ::
    Server.t
    | nil
  @doc """
  Fetches the server that mounts the `motherboard`
  """
  defdelegate fetch_by_motherboard(motherboard_id),
    to: ServerInternal

  @spec get_ip(Server.id, Network.id) ::
    NetworkConnection.ip
    | nil
  def get_ip(server_id, network_id) do
    case CacheQuery.from_server_get_nips(server_id) do
      {:ok, nips} ->
        # FIXME
        netconn = Enum.find(nips, &(&1.network_id == to_string(network_id)))
        netconn[:ip]
      _ ->
        nil
    end
  end
end
