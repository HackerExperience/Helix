defmodule Helix.Server.Query.Server do

  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Hardware.Model.Component
  alias Helix.Hardware.Model.NetworkConnection
  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Server
  alias Helix.Server.Query.Server.Origin, as: ServerQueryOrigin

  @spec fetch(Server.id) ::
    Server.t
    | nil
  @doc """
  Fetches a server
  """
  defdelegate fetch(server_id),
    to: ServerQueryOrigin

  @spec fetch_by_motherboard(Component.id) ::
    Server.t
    | nil
  @doc """
  Fetches the server that mounts the `motherboard`
  """
  defdelegate fetch_by_motherboard(motherboard_id),
    to: ServerQueryOrigin

  @spec fetch_by_nip(Network.id, NetworkConnection.ip) ::
    Server.t
    | nil
  defdelegate fetch_by_nip(network_id, ip),
    to: ServerQueryOrigin

  @spec get_nips(Server.id) ::
    [%{ip: NetworkConnection.ip, network_id: Network.id}]
  def get_nips(server_id) do
    {:ok, nips} = CacheQuery.from_server_get_nips(server_id)
    nips
  end

  @spec get_ip(Server.id, Network.id) ::
    %{ip: NetworkConnection.ip, network_id: Network.id}
    | nil
  def get_ip(server_id, network_id) do
    server_id
    |> get_nips()
    |> Enum.find(&(&1.network_id == network_id))
  end

  defmodule Origin do

    alias Helix.Server.Internal.Server, as: ServerInternal
    alias Helix.Hardware.Query.Motherboard, as: MotherboardQuery

    defdelegate fetch(server_id),
      to: ServerInternal

    defdelegate fetch_by_motherboard(motherboard_id),
      to: ServerInternal

    def fetch_by_nip(network_id, ip) do
      case MotherboardQuery.fetch_by_nip(network_id, ip) do
        nil ->
          nil
        motherboard_id ->
          fetch_by_motherboard(motherboard_id)
      end
    end
  end
end
