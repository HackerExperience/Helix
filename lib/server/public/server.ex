defmodule Helix.Server.Public.Server do

  alias Helix.Event
  alias Helix.Network.Action.Flow.Tunnel, as: TunnelFlow
  alias Helix.Network.Model.Connection
  alias Helix.Network.Model.Network
  alias Helix.Network.Model.Tunnel
  alias Helix.Server.Model.Component
  alias Helix.Server.Model.Server
  alias Helix.Server.Action.Flow.Server, as: ServerFlow
  alias Helix.Server.Action.Motherboard, as: MotherboardAction
  alias Helix.Server.Public.Index, as: ServerIndex
  alias Helix.Server.Query.Motherboard, as: MotherboardQuery

  @spec connect_to_server(
    Network.id, Server.id, Server.id, Tunnel.bounce, Event.relay)
  ::
    {:ok, Tunnel.t, Connection.ssh}
    | {:error, Tunnel.creation_error}
  @doc """
  Creates an initial connection to the server, used upon ServerJoin (hence the
  connection of type `:ssh`).
  """
  def connect_to_server(network_id, gateway_id, target_id, bounce, relay) do
    TunnelFlow.connect_once(
      network_id, gateway_id, target_id, bounce, {:ssh, %{}}, relay
    )
  end

  @spec update_mobo(
    Server.t,
    {
      Component.mobo,
      [MotherboardAction.update_component],
      [MotherboardAction.update_nc]
    },
    [Network.Connection.t],
    Event.relay)
  ::
    ServerFlow.update_mobo_result
  @doc """
  Updates the server motherboard.

  - `mobo` points to the (potentially) new motherboard component.
  - `components` is a list of the (potentially) new components linked to the
    motherboard.
  - `ncs` is a list of the (potentially) new NCs assigned to its NICs.

  Notice `components` and `ncs` are no ordinary lists. The former also includes
  the `slot_id` that component is supposed to be linked to, and the latter
  includes the `nic_id` that should be assigned the network connection (NC).
  """
  def update_mobo(server, {mobo, components, ncs}, entity_ncs, relay) do
    motherboard =
      if server.motherboard_id do
        MotherboardQuery.fetch(server.motherboard_id)
      else
        nil
      end

    mobo_data =
      %{
        mobo: mobo,
        components: components,
        network_connections: ncs
      }

    ServerFlow.update_mobo(server, motherboard, mobo_data, entity_ncs, relay)
  end

  @doc """
  Detaches the server motherboard.
  """
  defdelegate detach_mobo(server, motherboard, relay),
    to: ServerFlow

  @doc """
  Sets the server hostname.
  """
  defdelegate set_hostname(server, hostname, relay),
    to: ServerFlow

  defdelegate bootstrap_gateway(server_id, entity_id),
    to: ServerIndex,
    as: :gateway

  defdelegate bootstrap_remote(server_id, entity_id),
    to: ServerIndex,
    as: :remote

  defdelegate render_bootstrap_gateway(bootstrap),
    to: ServerIndex,
    as: :render_gateway

  defdelegate render_bootstrap_remote(bootstrap),
    to: ServerIndex,
    as: :render_remote
end
