defmodule Helix.Software.Event.File do

  import Helix.Event

  event Downloaded do
    @moduledoc """
    FileDownloadedEvent is fired when a FileTransfer process of type `download`
    has finished successfully, in which case a new file has been transferred to
    the corresponding server.
    """

    alias Helix.Entity.Model.Entity
    alias Helix.Network.Model.Network
    alias Helix.Server.Model.Server
    alias Helix.Software.Model.File
    alias Helix.Software.Model.Storage

    alias Helix.Software.Event.File.Transfer.Processed,
      as: FileTransferProcessedEvent

    @type t :: %__MODULE__{
      entity_id: Entity.id,
      to_server_id: Server.id,
      from_server_id: Server.id,
      file: File.t,
      to_storage_id: Storage.id,
      network_id: Network.id,
      connection_type: :ftp | :public_ftp
    }

    event_struct [
      :entity_id,
      :to_server_id,
      :from_server_id,
      :file,
      :to_storage_id,
      :network_id,
      :connection_type
    ]

    @spec new(FileTransferProcessedEvent.t, File.t) ::
      t
    def new(
      transfer = %FileTransferProcessedEvent{type: :download},
      file = %File{})
    do
      %__MODULE__{
        entity_id: transfer.entity_id,
        to_server_id: transfer.to_server_id,
        from_server_id: transfer.from_server_id,
        to_storage_id: transfer.to_storage_id,
        network_id: transfer.network_id,
        connection_type: transfer.connection_type,
        file: file
      }
    end

    notify do
      @moduledoc """
      Notifies the Client that a file has been downloaded.
      """

      @event :file_downloaded

      def generate_payload(event, _socket) do
        data = %{
          file: event.file.id
        }

        {:ok, data}
      end

      @doc """
      We only notify the "downloader" server.
      """
      def whom_to_notify(event),
        do: %{server: event.to_server_id}
    end

    loggable do

      @doc """
      Generates a log entry when a File has been downloaded from a Public FTP
      server.

      In this case, to protect the downloader's identity and honor the "public"
      part, we censor the downloader's IP address, which will be saved on the
      PublicFTP host server, but with 5 digits censored.

      On the other hand, the host server IP address is not censored, and will be
      saved fully on the downloader's server.
      """
      log(event = %{connection_type: :public_ftp}) do
        ip_from = get_ip(event.from_server_id, event.network_id)
        ip_to = get_ip(event.to_server_id, event.network_id) |> censor_ip()

        file_name = get_file_name(event.file)

        msg_to = "localhost downloaded file #{file_name} from Public FTP server #{ip_from}"
        msg_from = "#{ip_to} downloaded file #{file_name} from localhost Public FTP"

        log_from = build_entry(event.from_server_id, event.entity_id, msg_from)
        log_to = build_entry(event.to_server_id, event.entity_id, msg_to)

        [log_from, log_to]
      end

      @doc """
      Generates a log  entry when a File has been downloaded from a server.
      """
      log(event = %{connection_type: :ftp}) do
        ip_from = get_ip(event.from_server_id, event.network_id)
        ip_to = get_ip(event.to_server_id, event.network_id)

        file_name = get_file_name(event.file)

        msg_to = "localhost downloaded file #{file_name} from #{ip_from}"
        msg_from = "#{ip_to} downloaded file #{file_name} from localhost"

        log_from = build_entry(event.from_server_id, event.entity_id, msg_from)
        log_to = build_entry(event.to_server_id, event.entity_id, msg_to)

        [log_from, log_to]
      end
    end
  end

  event DownloadFailed do
    @moduledoc """
    FileDownloadFailedEvent is fired when a FileTransfer process of type
    `download` has finished with problems, in which case the transfer of the
    file was NOT successful.
    """

    alias Helix.Entity.Model.Entity
    alias Helix.Network.Model.Network
    alias Helix.Server.Model.Server

    alias Helix.Software.Event.File.Transfer.Processed,
      as: FileTransferProcessedEvent

    @type reason ::
      :no_space_left
      | :file_not_found
      | :unknown

    @type t :: %__MODULE__{
      reason: reason,
      entity_id: Entity.id,
      to_server_id: Server.id,
      from_server_id: Server.id,
      network_id: Network.id,
      connection_type: :ftp | :public_ftp
    }

    event_struct [
      :reason,
      :entity_id,
      :to_server_id,
      :from_server_id,
      :network_id,
      :connection_type
    ]

    @spec new(FileTransferProcessedEvent.t, reason) ::
      t
    def new(transfer = %FileTransferProcessedEvent{type: :download}, reason) do
      %__MODULE__{
        entity_id: transfer.entity_id,
        to_server_id: transfer.to_server_id,
        from_server_id: transfer.from_server_id,
        network_id: transfer.network_id,
        connection_type: transfer.connection_type,
        reason: reason
      }
    end
  end

  event Uploaded do
    @moduledoc """
    FileUploadedEvent is fired when a FileTransfer process of type `upload` has
    finished successfully, in which case a new file has been transferred to the
    corresponding server.
    """

    alias Helix.Entity.Model.Entity
    alias Helix.Network.Model.Network
    alias Helix.Server.Model.Server
    alias Helix.Software.Model.File
    alias Helix.Software.Model.Storage

    alias Helix.Software.Event.File.Transfer.Processed,
      as: FileTransferProcessedEvent

    @type t :: %__MODULE__{
      entity_id: Entity.id,
      to_server_id: Server.id,
      from_server_id: Server.id,
      file: File.t,
      to_storage_id: Storage.id,
      network_id: Network.id
    }

    event_struct [
      :entity_id,
      :to_server_id,
      :from_server_id,
      :file,
      :to_storage_id,
      :network_id
    ]

    @spec new(FileTransferProcessedEvent.t, File.t) ::
      t
    def new(
      transfer = %FileTransferProcessedEvent{type: :upload},
      file = %File{})
    do
      %__MODULE__{
        entity_id: transfer.entity_id,
        to_server_id: transfer.to_server_id,
        from_server_id: transfer.from_server_id,
        to_storage_id: transfer.to_storage_id,
        network_id: transfer.network_id,
        file: file
      }
    end
  end

  event UploadFailed do
    @moduledoc """
    FileUploadFailedEvent is fired when a FileTransfer process of type `upload`
    has finished with problems, in which case the transfer of the file was NOT
    successful.
    """

    alias Helix.Entity.Model.Entity
    alias Helix.Network.Model.Network
    alias Helix.Server.Model.Server

    alias Helix.Software.Event.File.Transfer.Processed,
      as: FileTransferProcessedEvent

    @type reason ::
      :no_space_left
      | :file_not_found
      | :unknown

    @type t :: %__MODULE__{
      reason: reason,
      entity_id: Entity.id,
      to_server_id: Server.id,
      from_server_id: Server.id,
      network_id: Network.id
    }

    event_struct [
      :reason,
      :entity_id,
      :to_server_id,
      :from_server_id,
      :network_id
    ]

    @spec new(FileTransferProcessedEvent.t, reason) ::
      t
    def new(transfer = %FileTransferProcessedEvent{type: :upload}, reason) do
      %__MODULE__{
        entity_id: transfer.entity_id,
        to_server_id: transfer.to_server_id,
        from_server_id: transfer.from_server_id,
        network_id: transfer.network_id,
        reason: reason
      }
    end
  end
end
