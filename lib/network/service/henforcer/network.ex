defmodule Helix.Network.Service.Henforcer.Network do

  alias Helix.Hardware.Controller.Component
  alias Helix.Hardware.Controller.Motherboard
  alias Helix.Server.Controller.Server
  alias Helix.Network.Controller.Tunnel, as: TunnelController

  @spec node_connected?(HELL.PK.t, HELL.PK.t) ::
    boolean
  def node_connected?(server, network) do
    # FIXME: This looks awful
    # FIXME: Test (needs network factory and some patience)
    with \
      %{motherboard_id: motherboard} <- Server.fetch(server),
      component = %{} <- Component.fetch(motherboard),
      motherboard = %{} <- Motherboard.fetch!(component),
      %{net: %{^network => _}} <- Motherboard.resources(motherboard)
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
    connections_between = TunnelController.connections_on_tunnels_between(
      gateway,
      destination)
    connection_types = MapSet.new(connections_between, &(&1.connection_type))

    MapSet.member?(connection_types, "ssh")
  end
end
