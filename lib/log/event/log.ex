defmodule Helix.Log.Event.Log do
  @moduledoc false

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
  alias Helix.Software.Model.SoftwareType.LogForge.Edit.ConclusionEvent,
    as: LogForgeEditComplete
  alias Helix.Software.Model.SoftwareType.LogForge.Create.ConclusionEvent,
    as: LogForgeCreateComplete

  @doc """
  Logs that a file was downloaded from a certain server
  """
  def file_download_conclusion(event = %DownloadComplete{}) do
    from = event.from_server_id
    to = event.to_server_id
    ip_from = ServerQuery.get_ip(from, event.network_id)
    ip_to = ServerQuery.get_ip(to, event.network_id)

    entity = EntityQuery.fetch_by_server(to)

    file = FileQuery.fetch(event.from_file_id)
    # FIXME: move to a view helper
    file_name =
      file.full_path
      |> String.split("/")
      |> List.last()

    message_from = "File #{file_name} downloaded by #{ip_to}"
    message_to = "File #{file_name} downloaded from #{ip_from}"

    {:ok, events} = Repo.transaction fn ->
      {:ok, _, e1} = LogAction.create(from, entity, message_from)
      {:ok, _, e2} = LogAction.create(to, entity, message_to)
      e1 ++ e2
    end

    Event.emit(events)
  end

  @doc """
  Forges a revision onto a log or creates a fake new log
  """
  def log_forge_conclusion(event = %LogForgeEditComplete{}) do
    {:ok, _, events} =
      event.target_log_id
      |> LogQuery.fetch()
      |> LogAction.revise(event.entity_id, event.message, event.version)

    Event.emit(events)
  end

  def log_forge_conclusion(event = %LogForgeCreateComplete{}) do
    {:ok, _, events} = LogAction.create(
      event.server_id,
      event.entity_id,
      event.message,
      event.version)

    Event.emit(events)
  end

  @doc """
  Logs that a server logged into another via SSH
  """
  def connection_started(
    event = %ConnectionStartedEvent{connection_type: "ssh"})
  do
    tunnel = TunnelQuery.fetch(event.tunnel_id)
    network = event.network_id
    gateway = tunnel.gateway_id
    destination = tunnel.destination_id

    gateway_ip = ServerQuery.get_ip(gateway, network)
    destination_ip = ServerQuery.get_ip(destination, network)

    entity = EntityQuery.fetch_by_server(gateway)

    message_orig = "Logged into #{destination_ip}"
    message_dest = "#{gateway_ip} logged in as root"

    {:ok, events} = Repo.transaction fn ->
      {:ok, _, e1} = LogAction.create(gateway, entity, message_orig)
      {:ok, _, e2} = LogAction.create(destination, entity, message_dest)
      e1 ++ e2
    end

    Event.emit(events)
  end

  def connection_started(_) do
    :ignore
  end
end
