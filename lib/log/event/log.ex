defmodule Helix.Log.Event.Log do

  alias Helix.Event
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Network.Model.Connection.ConnectionStartedEvent
  alias Helix.Network.Query.Tunnel, as: TunnelQuery
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Software.Query.File, as: FileQuery
  alias Helix.Log.Action.Log, as: LogAction
  alias Helix.Log.Query.Log, as: LogQuery
  alias Helix.Log.Repo

  alias Helix.Software.Model.SoftwareType.FileDownload.ProcessConclusionEvent,
    as: DownloadComplete
  alias Helix.Software.Model.SoftwareType.LogForge.ProcessConclusionEvent,
    as: LogForgeComplete

  def file_download_conclusion(event = %DownloadComplete{}) do
    to = event.to_server_id
    from = event.from_server_id
    ip_to = ServerQuery.get_ip(to, event.network_id)
    ip_from = ServerQuery.get_ip(from, event.network_id)

    entity = EntityQuery.fetch_by_server(to)

    file = FileQuery.fetch(event.from_file_id)
    # FIXME: move to a view helper
    file_name =
      file.full_path
      |> String.split("/")
      |> List.last()

    message_from = "File #{file_name} downloaded by #{ip_to}"
    message_to = "File #{file_name} downloaded from #{ip_from}"

    # TODO: Wrap into a transaction and emit events only on success
    Repo.transaction fn ->
      LogAction.create(from, entity, message_from)
      LogAction.create(to, entity, message_to)
    end
  end

  def log_forge_conclusion(event = %LogForgeComplete{}) do
    {:ok, _, events} =
      event.target_log_id
      |> LogQuery.fetch()
      |> LogAction.revise(event.entity_id, event.message, event.version)

    Event.emit(events)
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

    entity = EntityQuery.fetch_by_server(gateway_id)

    message_gateway = "Logged into #{destination_ip}"
    message_destination = "#{gateway_ip} logged in as root"

    # TODO: Wrap into a transaction and emit events only on success
    Repo.transaction fn ->
      LogAction.create(gateway_id, entity, message_gateway)
      LogAction.create(destination_id, entity, message_destination)
    end
  end

  def connection_started(_) do
    :ignore
  end
end
