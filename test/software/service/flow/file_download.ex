defmodule Helix.Software.Service.Flow.FileDownload do

  alias Helix.Event
  alias Helix.Network.Controller.Tunnel, as: TunnelController
  alias Helix.Network.Model.Tunnel
  alias Helix.Process.Service.API.Process
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Storage
  alias Software.FileDownload.ProcessType

  @spec start_download_process(File.t, Storage.t, Tunnel.t) ::
    {:ok, struct}
  def start_download_process(origin_file, destination_storage, tunnel) do
    objective = %{dlk: origin_file.file_size}
    process_data = %ProcessType{
      target_file_id: origin_file.file_id,
      destination_storage_id: destination_storage.storage_id
    }

    %Tunnel{
      gateway_id: gateway,
      destination_id: destination,
      network_id: network
    } = tunnel

    # TODO: limitations
    params = %{
      gateway_id: gateway,
      target_server_id: destination,
      network_id: network,
      connection_id: nil,
      process_data: process_data,
      process_type: "file_download"
    }

    start_connection = fn ->
      TunnelController.start_connection(tunnel, "ftp")
    end

    flowing do
      with \
        {:ok, connection, events} <- start_connection.(),
        on_fail(fn -> TunnelController.close_connection(connection) end),
        on_done(fn -> Event.emit(events) end),

        params = %{params| connection_id: connection.connection_id},

        {:ok, process} = Process.create(params)
      do
        # Yay!
        # TODO: what is the proper return ?
        {:ok, process}
      end
    end
  end
end
