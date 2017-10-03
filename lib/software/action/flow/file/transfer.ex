defmodule Helix.Software.Action.Flow.File.Transfer do

  import HELF.Flow

  alias Helix.Event
  alias Helix.Network.Action.Tunnel, as: TunnelAction
  alias Helix.Network.Model.Network
  alias Helix.Network.Query.Network, as: NetworkQuery
  alias Helix.Process.Action.Process, as: ProcessAction
  alias Helix.Process.Model.Process
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.File
  alias Helix.Software.Process.File.Transfer, as: FileTransferProcess

  @type transfer_type ::
    :download
    | :pftp_download
    | :upload

  @type network_info :: %{
    gateway_id: Server.id,
    destination_id: Server.id,
    network_id: Network.id,
    bounces: [Server.id]
  }

  @type transfer_ok ::
    {:ok, Process.t}

  @type transfer_error ::
    term

  @spec transfer(transfer_type, File.t, Storage.t, network_info) ::
    transfer_ok
    | transfer_error
  def transfer(type, file, destination_storage, network_info) do
    {connection_type, process_type, transfer_type} =
      case type do
        :download ->
          {:ftp, "file_download", :download}
        :upload ->
          {:ftp, "file_upload", :upload}
        :pftp_download ->
          {:public_ftp, "file_download", :download}
      end

    objective = FileTransferProcess.objective(transfer_type, file)

    process_data = %FileTransferProcess{
      type: transfer_type,
      destination_storage_id: destination_storage.storage_id,
      connection_type: connection_type
    }

    params = %{
      gateway_id: network_info.gateway_id,
      target_server_id: network_info.destination_id,
      network_id: network_info.network_id,
      file_id: file.file_id,
      connection_id: nil,
      objective: objective,
      process_data: process_data,
      process_type: process_type
    }

    start_connection = fn ->
      network = NetworkQuery.fetch(network_info.network_id)

      TunnelAction.connect(
        network,
        network_info.gateway_id,
        network_info.destination_id,
        network_info.bounces,
        connection_type
      )
    end

    flowing do
      with \
        {:ok, connection, events} <- start_connection.(),
        on_fail(fn -> TunnelAction.close_connection(connection) end),
        on_success(fn -> Event.emit(events) end),

        params = %{params| connection_id: connection.connection_id},

        {:ok, process, events} = ProcessAction.create(params),
        on_success(fn -> Event.emit(events) end)
      do
        {:ok, process}
      end
    end
  end
end
