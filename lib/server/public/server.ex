defmodule Helix.Server.Public.Server do

  alias Helix.Event
  alias Helix.Entity.Model.Entity
  alias Helix.Log.Model.Log
  alias Helix.Log.Public.Log, as: LogPublic
  alias Helix.Process.Public.Process, as: ProcessPublic
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.File
  alias Helix.Software.Public.File, as: FilePublic
  alias Helix.Network.Action.Tunnel, as: TunnelAction
  alias Helix.Network.Model.Network
  alias Helix.Network.Model.Tunnel
  alias Helix.Network.Query.Network, as: NetworkQuery
  alias Helix.Network.Query.Tunnel, as: TunnelQuery

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
        "ssh"),
      tunnel = %{} <- TunnelQuery.fetch_from_connection(connection)
    do
      Event.emit(events)

      {:ok, %{tunnel: tunnel}}
    end
  end

  @spec log_index(Server.id) ::
    [map]
  defdelegate log_index(server_id),
    to: LogPublic,
    as: :index

  @spec log_delete(Server.id, Server.id, Network.id, Log.id) ::
    :ok
    | {:error, :nxlog | :unknown}
  defdelegate log_delete(gateway_id, target_id, network_id, log_id),
    to: LogPublic,
    as: :delete

  @spec file_index(Server.id) ::
    %{path :: String.t => [map]}
  defdelegate file_index(server_id),
    to: FilePublic,
    as: :index

  @spec file_download(Server.id, Server.id, Tunnel.t, File.id) ::
    :ok
    | :error
  defdelegate file_download(gateway_id, destination_id, tunnel, file_id),
    to: FilePublic,
    as: :download

  @spec process_index(Server.id, Entity.id) ::
    %{owned: [map], affecting: [map]}
  defdelegate process_index(server_id, entity_id),
    to: ProcessPublic,
    as: :index
end
