defmodule Helix.Log.Service.Event.Log do

  alias Helix.Event
  alias Helix.Entity.Service.API.Entity
  alias Helix.Hardware.Service.API.NetworkConnection
  alias Helix.Software.Service.API.File
  alias Helix.Software.Model.SoftwareType.FileDownload.ProcessConclusionEvent,
    as: DownloadComplete
  alias Helix.Log.Service.API.Log

  def file_download_conclusion(event = %DownloadComplete{}) do
    to = event.to_server_id
    from = event.from_server_id
    ip_to = NetworkConnection.get_server_ip(to, event.network_id)
    ip_from = NetworkConnection.get_server_ip(from, event.network_id)

    entity = Entity.fetch_server_owner(to)

    file = File.fetch(event.from_file_id)
    # FIXME: move to a view helper
    file_name =
      file.full_path
      |> String.split("/")
      |> List.last()

    message_from = "File #{file_name} downloaded by #{ip_to}"
    message_to = "File #{file_name} downloaded from #{ip_from}"

    # TODO: Wrap into a transaction
    {:ok, %{events: e}} = Log.create(from, entity.entity_id, message_from)
    Event.emit(e)
    {:ok, %{events: e}} = Log.create(to, entity.entity_id, message_to)
    Event.emit(e)
  end
end
