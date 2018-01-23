defmodule Helix.Network.Henforcer.Network do

  import Helix.Henforcer

  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Server.Model.Server
  alias Helix.Server.Henforcer.Server, as: ServerHenforcer
  alias Helix.Network.Model.Network
  alias Helix.Network.Query.Network, as: NetworkQuery

  @type nip_exists_relay :: %{server: Server.t}
  @type nip_exists_relay_partial :: %{}
  @type nip_exists_error ::
    {false, {:nip, :not_found}, nip_exists_relay_partial}
    | nip_exists_error

  @spec nip_exists?(Network.id, Network.ip) ::
    {true, nip_exists_relay}
    | nip_exists_error
  @doc """
  Henforces the given NIP belongs to a real server.
  """
  def nip_exists?(network_id = %Network.ID{}, ip) do
    case CacheQuery.from_nip_get_server(network_id, ip) do
      {:ok, server_id} ->
        henforce_else(
          ServerHenforcer.server_exists?(server_id),
          {:nip, :not_found}
        )

      {:error, _} ->
        reply_error({:nip, :not_found})
    end
  end

  @type network_exists_relay :: %{network: Network.t}
  @type network_exists_relay_partial :: %{}
  @type network_exists_error ::
    {false, {:network, :not_found}, network_exists_relay_partial}

  @spec network_exists?(Network.id) ::
    {true, network_exists_relay}
    | network_exists_error
  @doc """
  Henforce the given `network_id` exists.
  """
  def network_exists?(network_id = %Network.ID{}) do
    with network = %{} <- NetworkQuery.fetch(network_id) do
      reply_ok(%{network: network})
    else
      _ ->
        reply_error({:network, :not_found})
    end
  end

  @spec valid_origin?(
    origin :: Server.idtb,
    gateway_id :: Server.id,
    target_id :: Server.id)
  ::
    boolean
  @doc """
  If the user requests to use a custom `origin` header for DNS resolution, make
  sure it is either the `gateway_id` or the `target_id`
  """
  def valid_origin?(origin, gateway_id, target_id),
    do: origin == gateway_id or origin == target_id

  def can_bounce?(_origin_id, _network_id, _bounces) do
    #TODO 256
  end
end
