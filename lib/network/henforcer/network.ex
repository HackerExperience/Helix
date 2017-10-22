defmodule Helix.Network.Henforcer.Network do

  import Helix.Henforcer

  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Server.Model.Server
  alias Helix.Server.Henforcer.Server, as: ServerHenforcer
  alias Helix.Network.Model.Network

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

  ## Delete everything below this line ---

  alias Helix.Hardware.Query.Component, as: ComponentQuery
  alias Helix.Hardware.Query.Motherboard, as: MotherboardQuery
  alias Helix.Server.Model.Server
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Network.Model.Network
  alias Helix.Network.Query.Tunnel, as: TunnelQuery

  @spec node_connected?(Server.id, Network.id) ::
    boolean
  def node_connected?(server, network) do
    # FIXME: This looks awful
    # FIXME: Test (needs network factory and some patience)
    network_id = to_string(network)
    with \
      %{motherboard_id: motherboard} <- ServerQuery.fetch(server),
      component = %{} <- ComponentQuery.fetch(motherboard),
      motherboard = %{} <- MotherboardQuery.fetch(component),
      %{net: %{^network_id => _}} <- MotherboardQuery.resources(motherboard)
    do
      true
    else
      _ ->
        false
    end
  end

  @spec has_ssh_connection?(Server.id, Server.id) ::
    boolean
  def has_ssh_connection?(gateway, destination) do
    connections_between = TunnelQuery.connections_on_tunnels_between(
      gateway,
      destination)
    connection_types = MapSet.new(connections_between, &(&1.connection_type))

    MapSet.member?(connection_types, :ssh)
  end

  @spec valid_origin?(
    origin :: Server.idtb,
    gateway :: Server.id,
    destination :: Server.id)
  ::
    boolean
  @doc """
  If the user requests to use a custom `origin` header for DNS resolution, make
  sure it is either the `gateway_id` or the `destination_id`
  """
  def valid_origin?(origin, gateway_id, destination_id),
    do: origin == gateway_id or origin == destination_id

  def can_bounce?(_origin_id, _network_id, _bounces) do
    #TODO 256
  end
end
