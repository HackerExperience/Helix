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

  @spec fetch_by_motherboard(Motherboard.idt) ::
    Server.t
    | nil
  @doc """
  Fetches the server that mounts the `motherboard`
  """
  defdelegate fetch_by_motherboard(motherboard_id),
    to: ServerInternal

  @spec get_ip(Server.id, Network.idt) ::
    NetworkConnection.ip
    | nil
  def get_ip(server_id, network = %Network{}),
    do: get_ip(server_id, network.network_id)
  def get_ip(server_id, network_id) do
    case CacheQuery.from_server_get_nips(server_id) do
      {:ok, nips} ->
        nips
        |> Enum.find(&(&1.network_id) == network_id)
        |> Map.get(:ip)
      _ ->
        nil
    end
  end

  @spec get_password(Server.idt) ::
    {:ok, Server.password}
    | {:error, {:server, :notfound}}
  @doc """
  Returns the server password.
  """
  def get_password(server_id = %Server.ID{}) do
    server_id
    |> fetch()
    |> get_password()
  end
  def get_password(server = %Server{}),
    do: {:ok, server.password}
  def get_password(nil),
    do: {:error, {:server, :notfound}}
end
