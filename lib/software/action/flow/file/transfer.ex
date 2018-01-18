defmodule Helix.Software.Action.Flow.File.Transfer do

  import HELL.Macros

  alias Helix.Event
  alias Helix.Network.Model.Net
  alias Helix.Process.Model.Process
  alias Helix.Process.Query.Process, as: ProcessQuery
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Storage
  alias Helix.Software.Process.File.Transfer, as: FileTransferProcess

  @type transfer_result ::
    {:ok, Process.t}
    | transfer_error

  @type transfer_error ::
    FileTransferProcess.executable_error

  @typep type ::
    :download
    | :pftp_download
    | :upload

  @typep relay :: Event.relay

  @spec download(Server.t, Server.t, File.t, Storage.t, Net.t, relay) ::
    transfer_result
  @doc """
  Starts a FileDownload process.
  """
  def download(gateway, endpoint, file, storage, net, relay),
    do: transfer(:download, gateway, endpoint, file, storage, net, relay)

  @spec upload(Server.t, Server.t, File.t, Storage.t, Net.t, relay) ::
    transfer_result
  @doc """
  Starts a FileUpload process.
  """
  def upload(gateway, endpoint, file, storage, net, relay),
    do: transfer(:upload, gateway, endpoint, file, storage, net, relay)

  @spec pftp_download(Server.t, Server.t, File.t, Storage.t, Net.t, relay) ::
    transfer_result
  @doc """
  Starts a PFTPDownload process.
  """
  def pftp_download(gateway, endpoint, file, storage, net, relay),
    do: transfer(:pftp_download, gateway, endpoint, file, storage, net, relay)

  @spec transfer(type, Server.t, Server.t, File.t, Storage.t, Net.t, relay) ::
    transfer_result
  docp """
  Starts a FileTransfer process, which can be one of [pftp_]download or upload.

  If that exact file is already being transferred to/by the gateway, the
  existing process is returned and no new transfer is created. This ensures the
  same file cannot be transferred multiple times to/from the same server.
  """
  defp transfer(type, gateway, endpoint, file, storage, net, relay) do
    {_, process_type, _} = get_type_info(type)

    # Verifies whether that file is already being transferred to/by the gateway
    transfer_process =
      ProcessQuery.get_custom(
        process_type, gateway.server_id, %{tgt_file_id: file.file_id}
      )

    case transfer_process do
      # A transfer already exists, so we simply return the corresponding process
      [process] ->
        {:ok, process}

      # There's no transfer yet. We'll have to create a new one.
      nil ->
        do_transfer(type, gateway, endpoint, file, storage, net, relay)
    end
  end

  @spec do_transfer(type, Server.t, Server.t, File.t, Storage.t, Net.t, relay) ::
    transfer_result
  docp """
  Starts a FileTransfer process, which can be one of download or upload.
  """
  defp do_transfer(type, gateway, endpoint, file, storage, net, relay) do
    {connection_type, process_type, transfer_type} = get_type_info(type)

    params = %{
      type: transfer_type,
      destination_storage_id: storage.storage_id,
      connection_type: connection_type
    }

    meta = %{
      network_id: net.network_id,
      bounce: net.bounce_id,
      file: file,
      type: process_type
    }

    FileTransferProcess.execute(gateway, endpoint, params, meta, relay)
  end

  docp """
  Given the transfer type, figure out all related types used by other services.
  """
  defp get_type_info(:download),
    do: {:ftp, :file_download, :download}
  defp get_type_info(:upload),
    do: {:ftp, :file_upload, :upload}
  defp get_type_info(:pftp_download),
    do: {:public_ftp, :file_download, :download}
end
