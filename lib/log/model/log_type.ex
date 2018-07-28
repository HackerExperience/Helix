defmodule Helix.Log.Model.LogType do

  use Helix.Log.Model.LogType.Macros

  @type type ::
    :local_login
    | :remote_login_gateway
    | :remote_login_endpoint
    | :connection_bounced

  @type data :: struct | map

  log :local_login, 0 do
    @moduledoc """
    `LocalLoginLog` is the log displayed when the player logs into his own
    server.

      Localhost logged in
    """

    data_struct []

    gen0()
  end

  log :remote_login_gateway, 1 do
    @moduledoc """
    `RemoteLoginGatewayLog` is shown when a player logged into another server,
    from the gateway perspective.

      localhost logged into $ip as root
    """

    data_struct [:network_id, :ip]

    gen2({:network_id, :network}, {:ip, :ip})
  end

  log :remote_login_endpoint, 2 do
    @moduledoc """
    `RemoteLoginEndpointLog` is shown when a player logged into another server,
    from the endpoint perspective.

      $ip logged in as root
    """

    data_struct [:network_id, :ip]

    gen2({:network_id, :network}, {:ip, :ip})
  end

  log :connection_bounced, 3 do
    @moduledoc """
    `ConnectionBouncedLog` is the log displayed on intermediary hops (aka
    bounces) of a connection.

      Connection bounced from $ip_prev to $ip_next
    """

    data_struct [:network_id, :ip_prev, :ip_next]

    gen3({:network_id, :network}, {:ip_prev, :ip}, {:ip_next, :ip})
  end

  log :file_download_gateway, 4 do
    @moduledoc """
    `FileDownloadGateway` is the log displayed on the player who just downloaded
    a file.

      localhost downloaded file $file_name from $first_ip
    """

    data_struct [:file_name, :ip, :network_id]

    gen3({:file_name, :file_name}, {:ip, :ip}, {:network_id, :network})
  end

  log :file_download_endpoint, 5 do
    @moduledoc """
    `FileDownloadEndpoint` is the log displayed on the target server (endpoint)
    that just had a file downloaded from it.

      $last_ip downloaded file $file_name from localhost
    """

    data_struct [:file_name, :ip, :network_id]

    gen3({:file_name, :file_name}, {:ip, :ip}, {:network_id, :network})
  end

  log :file_upload_gateway, 6 do
    @moduledoc """
    `FileUploadGateway` is the log displayed on the player who just uploaded a
    file.

      localhost uploaded file $file_name to $first_ip
    """

    data_struct [:file_name, :ip, :network_id]

    gen3({:file_name, :file_name}, {:ip, :ip}, {:network_id, :network})
  end

  log :file_upload_endpoint, 7 do
    @moduledoc """
    `FileUploadEndpoint` is the log displayed on the target server (endpoint)
    that just had a file uploaded to it.

      $last_ip uploaded file $file_name to localhost
    """

    data_struct [:file_name, :ip, :network_id]

    gen3({:file_name, :file_name}, {:ip, :ip}, {:network_id, :network})
  end

  log :pftp_file_download_gateway, 8 do
    @moduledoc """
    `PFTPFileDownloadedGateway` is the log displayed on the gateway of the
    player who just finished downloading a file from a PFTP server.

    Bounces are skipped.

      localhost downloaded $file_name from public FTP server at $endpoint_ip
    """

    data_struct [:file_name, :ip, :network_id]

    gen3({:file_name, :file_name}, {:ip, :ip}, {:network_id, :network})
  end

  log :pftp_file_download_endpoint, 9 do
    @moduledoc """
    `PFTPFileDownloadedEndpoint` is the log displayed on the endpoint server
    that a player just finished downloading a file from.

    Bounces are skipped. Gateway IP is censored.

      $censored_gateway_ip downloaded $file_name from local public FTP server
    """

    data_struct [:file_name, :ip, :network_id]

    gen3({:file_name, :file_name}, {:ip, :ip}, {:network_id, :network})
  end

  log :virus_installed_gateway, 10 do
    @moduledoc """
    `VirusInstalledGateway` is the log displayed on the gateway of the player
    who just installed a virus on someone.

      localhost installed virus $file_name at $first_ip
    """

    data_struct [:file_name, :ip, :network_id]

    gen3({:file_name, :file_name}, {:ip, :ip}, {:network_id, :network})
  end

  log :virus_installed_endpoint, 11 do
    @moduledoc """
    `VirusInstalledEndpoint` is the log displayed on the endpoint server which
    the player just installed a virus on.

      $last_ip installed virus $file_name at localhost
    """

    data_struct [:file_name, :ip, :network_id]

    gen3({:file_name, :file_name}, {:ip, :ip}, {:network_id, :network})
  end
end
