defmodule Helix.Server.Public.Server do

  alias HELL.IPv4
  alias Helix.Event
  alias Helix.Network.Action.Tunnel, as: TunnelAction
  alias Helix.Network.Model.Network
  alias Helix.Network.Model.Tunnel
  alias Helix.Network.Public.Network, as: NetworkPublic
  alias Helix.Network.Query.Network, as: NetworkQuery
  alias Helix.Network.Query.Tunnel, as: TunnelQuery
  alias Helix.Process.Model.Process
  alias Helix.Software.Action.Flow.File, as: FileFlow
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Storage
  alias Helix.Software.Public.File, as: FilePublic
  alias Helix.Server.Model.Server
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

  @spec file_download(Tunnel.t, Storage.idt, File.idt) ::
    {:ok, Process.t}
    | {:error, %{message: String.t}}
  defdelegate file_download(tunnel, storage, file),
    to: FilePublic,
    as: :download

  @spec network_browse(Network.idt, String.t | IPv4.t, Server.idt) ::
    {:ok, term}
    | {:error, %{message: String.t}}
  defdelegate network_browse(network_id, address, origin_id),
    to: NetworkPublic,
    as: :browse

  @spec bruteforce(Server.id, Network.id, IPv4.t, [Server.id]) ::
    {:ok, Process.t}
    | FileFlow.error
  defdelegate bruteforce(gateway_id, network_id, target_ip, bounces),
    to: FilePublic

  defdelegate bootstrap(server_id, entity_id),
    to: ServerIndex,
    as: :remote_server_index

  defdelegate render_bootstrap(bootstrap),
    to: ServerIndex,
    as: :render_remote_server_index
end
