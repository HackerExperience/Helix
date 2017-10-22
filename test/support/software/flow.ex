defmodule Helix.Test.Software.Setup.Flow do

  alias Helix.Software.Process.Cracker.Bruteforce, as: BruteforceProcess
  alias Helix.Software.Process.File.Transfer, as: FileTransferProcess

  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Software.Helper, as: SoftwareHelper
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  @doc """
  Starts a FileTransferProcess (download or upload).
  """
  def file_transfer(type) do
    {gateway, _} = ServerSetup.server()
    {destination, _} = ServerSetup.server()
    {file, _} = SoftwareSetup.file(server_id: destination.server_id)

    {connection_type, process_type, transfer_type} = get_type_info(type)

    destination_server =
      if type == :upload do
        destination
      else
        gateway
      end

    destination_storage = SoftwareHelper.get_storage(destination_server)

    params = %{
      type: transfer_type,
      connection_type: connection_type,
      destination_storage_id: destination_storage.storage_id
    }

    meta = %{
      network_id: NetworkHelper.internet_id(),
      bounce: [],
      file: file,
      process_type: process_type
    }

    {:ok, process} =
      FileTransferProcess.execute(gateway, destination, params, meta)

    {process, %{}}
  end

  defp get_type_info(:download),
    do: {:ftp, "file_download", :download}
  defp get_type_info(:upload),
    do: {:ftp, "file_upload", :upload}
  defp get_type_info(:pftp_download),
    do: {:public_ftp, "file_download", :download}

  @doc """
  Starts a BruteforceProcess.
  """
  def bruteforce do
    {source_server, %{entity: source_entity}} = ServerSetup.server()
    {target_server, _} = ServerSetup.server()

    target_nip = ServerHelper.get_nip(target_server)

    {file, _} =
      SoftwareSetup.file([type: :cracker, server_id: source_server.server_id])

    params = %{
      target_server_ip: target_nip.ip
    }

    meta = %{
      network_id: target_nip.network_id,
      bounce: [],
      cracker: file
    }

    {:ok, process} =
      BruteforceProcess.execute(source_server, target_server, params, meta)

    related = %{
      source_server: source_server,
      source_entity: source_entity,
      target_server: target_server,
      target_ip: target_nip.ip,
      network_id: target_nip.network_id
    }

    {process, related}
  end
end
