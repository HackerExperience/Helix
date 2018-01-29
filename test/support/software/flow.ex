defmodule Helix.Test.Software.Setup.Flow do

  alias Helix.Software.Process.Cracker.Bruteforce, as: BruteforceProcess
  alias Helix.Software.Process.File.Transfer, as: FileTransferProcess
  alias Helix.Software.Process.File.Install, as: FileInstallProcess

  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Network.Setup, as: NetworkSetup
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
      bounce: nil,
      file: file,
      type: process_type
    }

    {:ok, process} =
      FileTransferProcess.execute(gateway, destination, params, meta, nil)

    {process, %{}}
  end

  defp get_type_info(:download),
    do: {:ftp, :file_download, :download}
  defp get_type_info(:upload),
    do: {:ftp, :file_upload, :upload}
  defp get_type_info(:pftp_download),
    do: {:public_ftp, :file_download, :download}

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
      bounce: nil,
      cracker: file
    }

    {:ok, process} =
      BruteforceProcess.execute(source_server, target_server, params, meta, nil)

    related = %{
      source_server: source_server,
      source_entity: source_entity,
      target_server: target_server,
      target_ip: target_nip.ip,
      network_id: target_nip.network_id
    }

    {process, related}
  end

  @doc """
  Starts a virus install process.

  Opts:
  - with_bounce: Whether to generate the process with bounce. Defaults to false.
  - bounce_total: Total bounce links. Defaults to 3. Only used if `with_bounce`.
  """
  def install_virus(opts \\ []) do
    {source_server, %{entity: source_entity}} = ServerSetup.server()
    {target_server, _} = ServerSetup.server()

    bounce_id =
      if Keyword.get(opts, :with_bounce) do
        total = Keyword.get(opts, :bounce_total, 3)
        {bounce, _} = NetworkSetup.Bounce.bounce(total: total)

        bounce.bounce_id
      else
        nil
      end

    {tunnel, _} =
      NetworkSetup.tunnel(
        gateway_id: source_server.server_id,
        target_id: target_server.server_id,
        bounce_id: bounce_id
      )

    ssh = NetworkSetup.connection!(type: :ssh, tunnel_id: tunnel.tunnel_id)

    {virus, _} = SoftwareSetup.virus(server_id: target_server.server_id)

    params = %{backend: :virus}

    meta = %{
      file: virus,
      type: :install_virus,
      network_id: tunnel.network_id,
      bounce: tunnel.bounce_id,
      ssh: ssh
    }

    {:ok, process} =
      FileInstallProcess.execute(
        source_server, target_server, params, meta, nil
      )

    related =
      %{
        tunnel: tunnel,
        ssh: ssh,
        source_server: source_server,
        source_entity: source_entity,
        target_server: target_server,
        virus: virus
      }

    {process, related}
  end
end
