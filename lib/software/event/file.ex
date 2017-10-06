defmodule Helix.Software.Event.File do

  defmodule Downloaded do
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

    @type t :: %__MODULE__{
      entity_id: Entity.id,
      to_server_id: Server.id,
      from_server_id: Server.id,
      file: File.t,
      to_storage_id: Storage.id,
      network_id: Network.id,
      connection_type: :ftp | :public_ftp
    }

    @enforce_keys [
      :entity_id,
      :to_server_id,
      :from_server_id,
      :file,
      :network_id,
      :connection_type,
      :to_storage_id
    ]
    defstruct [
      :entity_id,
      :to_server_id,
      :from_server_id,
      :file,
      :to_storage_id,
      :network_id,
      :connection_type
    ]

    defimpl Helix.Event.Notificable do
      @moduledoc """
      Notifies the Client that a file has been downloaded.
      """

      @event "file_downloaded"

      def generate_payload(event, _socket) do
        data = %{
          file: event.file.id
        }

        return = %{
          data: data,
          event: @event
        }

        {:ok, return}
      end

      @doc """
      We only notify the "downloader" server.
      """
      def whom_to_notify(event),
        do: %{server: event.to_server_id}
    end
  end

  defmodule DownloadFailed do
    @moduledoc """
    FileDownloadFailedEvent is fired when a FileTransfer process of type
    `download` has finished with problems, in which case the transfer of the
    file was NOT successful.
    """

    alias Helix.Entity.Model.Entity
    alias Helix.Network.Model.Network
    alias Helix.Server.Model.Server
    alias Helix.Software.Model.Storage

    @type reason ::
      :no_space_left
      | :file_not_found
      | :unknown

    @type t :: %__MODULE__{
      reason: reason,
      entity_id: Entity.id,
      to_server_id: Server.id,
      from_server_id: Server.id,
      to_storage_id: Storage.id,
      network_id: Network.id,
      connection_type: :ftp | :public_ftp
    }

   @enforce_keys [
      :reason,
      :entity_id,
      :to_server_id,
      :from_server_id,
      :network_id,
      :connection_type
    ]
    defstruct [
      :reason,
      :entity_id,
      :to_server_id,
      :from_server_id,
      :to_storage_id,
      :network_id,
      :connection_type
    ]
  end

  defmodule Uploaded do
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

    @type t :: %__MODULE__{
      entity_id: Entity.id,
      to_server_id: Server.id,
      from_server_id: Server.id,
      file: File.t,
      to_storage_id: Storage.id,
      network_id: Network.id
    }

    @enforce_keys [
      :entity_id,
      :to_server_id,
      :from_server_id,
      :file,
      :network_id,
      :to_storage_id
    ]
    defstruct [
      :entity_id,
      :to_server_id,
      :from_server_id,
      :file,
      :to_storage_id,
      :network_id
    ]
  end

  defmodule UploadFailed do
    @moduledoc """
    FileUploadFailedEvent is fired when a FileTransfer process of type `upload`
    has finished with problems, in which case the transfer of the file was NOT
    successful.
    """

    alias Helix.Entity.Model.Entity
    alias Helix.Network.Model.Network
    alias Helix.Server.Model.Server
    alias Helix.Software.Model.Storage

    @type reason ::
      :no_space_left
      | :file_not_found
      | :unknown

    @type t :: %__MODULE__{
      reason: reason,
      entity_id: Entity.id,
      to_server_id: Server.id,
      from_server_id: Server.id,
      to_storage_id: Storage.id,
      network_id: Network.id
    }

    @enforce_keys [
      :reason,
      :entity_id,
      :to_server_id,
      :from_server_id,
      :network_id
    ]
    defstruct [
      :reason,
      :entity_id,
      :to_server_id,
      :from_server_id,
      :to_storage_id,
      :network_id
    ]
  end
end
