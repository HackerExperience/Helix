defmodule Helix.Log.Event.Log do

  alias Helix.Event
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Network.Model.Connection.ConnectionStartedEvent
  alias Helix.Network.Query.Tunnel, as: TunnelQuery
  alias Helix.Software.Query.File, as: FileQuery
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Software.Model.SoftwareType.LogDeleter.ProcessConclusionEvent,
    as: LogDeleteComplete
  alias Helix.Software.Model.SoftwareType.FileDownload.ProcessConclusionEvent,
    as: DownloadComplete
  alias Helix.Log.Action.Log, as: LogAction
  alias Helix.Log.Query.Log, as: LogQuery

  def file_download_conclusion(event = %DownloadComplete{}) do
    to = event.to_server_id
    from = event.from_server_id
    ip_to = ServerQuery.get_ip(to, event.network_id)
    ip_from = ServerQuery.get_ip(from, event.network_id)

    entity = EntityQuery.fetch_server_owner(to)

    file = FileQuery.fetch(event.from_file_id)
    # FIXME: move to a view helper
    file_name =
      file.full_path
      |> String.split("/")
      |> List.last()

    message_from = "File #{file_name} downloaded by #{ip_to}"
    message_to = "File #{file_name} downloaded from #{ip_from}"

    # TODO: Wrap into a transaction
    {:ok, %{events: e}} = LogAction.create(from, entity.entity_id, message_from)
    Event.emit(e)
    {:ok, %{events: e}} = LogAction.create(to, entity.entity_id, message_to)
    Event.emit(e)
  end

  def log_deleter_conclusion(%LogDeleteComplete{target_log_id: log}) do
    log
    |> LogQuery.fetch()
    |> LogAction.hard_delete()
  end

  def connection_started(
    event = %ConnectionStartedEvent{connection_type: "ssh"})
  do
    tunnel = TunnelQuery.fetch(event.tunnel_id)
    network = event.network_id
    gateway_id = tunnel.gateway_id
    destination_id = tunnel.destination_id

    gateway_ip = ServerQuery.get_ip(gateway_id, network)
    destination_ip = ServerQuery.get_ip(destination_id, network)

    entity = EntityQuery.fetch_server_owner(gateway_id)

    message_gateway = "Logged into #{destination_ip}"
    message_destination = "#{gateway_ip} logged in as root"

    # TODO: Wrap into a transaction
    {:ok, %{events: e}} = LogAction.create(
      gateway_id,
      entity.entity_id,
      message_gateway)
    Event.emit(e)
    {:ok, %{events: e}} = LogAction.create(
      destination_id,
      entity.entity_id,
      message_destination)
    Event.emit(e)
  end

  def connection_started(_) do
    :ignore
  end
end
