defmodule Helix.Network.Henforcer.Network do

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

  @type servers :: %{destination_id: Server.id, gateway_id: Server.id}
  @spec valid_origin?(Server.idtb, servers) ::
    boolean
  @doc """
  If the user requests to use a custom `origin` header for DNS resolution, make
  sure it is either the `gateway_id` or the `destination_id`
  """
  def valid_origin?(origin, servers),
    do: origin == servers.gateway_id or origin == servers.destination_id
end
