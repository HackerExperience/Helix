defmodule Helix.Network.Henforcer.Network do

  alias Helix.Hardware.Query.Component, as: ComponentQuery
  alias Helix.Hardware.Query.Motherboard, as: MotherboardQuery
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Network.Query.Tunnel, as: TunnelQuery

  @spec node_connected?(HELL.PK.t, HELL.PK.t) ::
    boolean
  def node_connected?(server, network) do
    # FIXME: This looks awful
    # FIXME: Test (needs network factory and some patience)
    with \
      %{motherboard_id: motherboard} <- ServerQuery.fetch(server),
      component = %{} <- ComponentQuery.fetch(motherboard),
      motherboard = %{} <- MotherboardQuery.fetch!(component),
      %{net: %{^network => _}} <- MotherboardQuery.resources(motherboard)
    do
      true
    else
      _ ->
        false
    end
  end

  @spec has_ssh_connection?(HELL.PK.t, HELL.PK.t) ::
    boolean
  def has_ssh_connection?(gateway, destination) do
    connections_between = TunnelQuery.connections_on_tunnels_between(
      gateway,
      destination)
    connection_types = MapSet.new(connections_between, &(&1.connection_type))

    MapSet.member?(connection_types, "ssh")
  end
end
