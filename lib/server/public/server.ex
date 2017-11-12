defmodule Helix.Server.Public.Server do

  alias Helix.Event
  alias Helix.Network.Action.Tunnel, as: TunnelAction
  alias Helix.Network.Model.Network
  alias Helix.Network.Model.Tunnel
  alias Helix.Network.Query.Network, as: NetworkQuery
  alias Helix.Network.Query.Tunnel, as: TunnelQuery
  alias Helix.Server.Model.Server
  alias Helix.Server.Action.Flow.Server, as: ServerFlow
  alias Helix.Server.Public.Index, as: ServerIndex

  @spec connect_to_server(Server.id, Server.id, [Server.id]) ::
    {:ok, Tunnel.t}
    | error :: term
  def connect_to_server(gateway_id, destination_id, bounce_list),
    do: connect_to_server(
      gateway_id,
      destination_id,
      bounce_list,
      NetworkQuery.internet())

  @spec connect_to_server(Server.id, Server.id, [Server.id], Network.t) ::
    {:ok, Tunnel.t}
    | error :: term
  def connect_to_server(gateway_id, destination_id, bounce_list, network) do
    with \
      {:ok, connection, events} <- TunnelAction.connect(
        network,
        gateway_id,
        destination_id,
        bounce_list,
        :ssh),
      tunnel = %{} <- TunnelQuery.fetch_from_connection(connection)
    do
      Event.emit(events)

      {:ok, tunnel}
    end
  end

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
