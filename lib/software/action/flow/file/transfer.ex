defmodule Helix.Software.Action.Flow.File.Transfer do

  import HELF.Flow
  import HELL.Macros

  alias Helix.Event
  alias Helix.Network.Action.Tunnel, as: TunnelAction
  alias Helix.Network.Model.Network
  alias Helix.Network.Query.Network, as: NetworkQuery
  alias Helix.Process.Action.Process, as: ProcessAction
  alias Helix.Process.Model.Process
  alias Helix.Process.Query.Process, as: ProcessQuery
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Storage
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
  @doc """
  Starts a FileTransfer process, which can be one of [pftp_]download or upload.

  If that exact file is already being transferred to/by the gateway, the
  existing process is returned and no new transfer is created. This ensures the
  same file cannot be transferred multiple times to/from the same server.
  """
  def transfer(type, file, destination_storage, network_info) do
    {_, process_type, _} = get_type_info(type)

    # Verifies whether that file is already being transferred to/by the gateway
    transfer_process =
      ProcessQuery.get_custom(
        process_type,
        network_info.gateway_id,
        %{file_id: file.file_id}
      )

    case transfer_process do
      # A transfer already exists, so we simply return the corresponding process
      [process] ->
        {:ok, process}

      # There's no transfer yet. We'll have to create a new one.
      nil ->
        new_transfer(type, file, destination_storage, network_info)
    end
  end

  @spec new_transfer(transfer_type, File.t, Storage.t, network_info) ::
    transfer_ok
    | transfer_error
  docp """
  Starts a FileTransfer process, which can be one of [pftp_]download or upload.
  """
  defp new_transfer(type, file, destination_storage, network_info) do
    {connection_type, process_type, transfer_type} = get_type_info(type)

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

  docp """
  Given the transfer type, figure out all related types used by other services.
  """
  defp get_type_info(:download),
    do: {:ftp, "file_download", :download}
  defp get_type_info(:upload),
    do: {:ftp, "file_upload", :upload}
  defp get_type_info(:pftp_download),
    do: {:public_ftp, "file_download", :download}
end
