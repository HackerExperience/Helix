defmodule Helix.Software.Event.File.Transfer do

  defmodule Processed do
    @moduledoc """
    FileTransferProcessed follows the Process standard and, as the name
    suggests, represents the conclusion of the given process. It will be used
    internally by Helix to figure out whether the transfer was successful or
    not.

    It may have multiple backends (download/upload/pftp_download), as explained
    on FileTransferProcess.

    Notification to the Client is useful so it can update the Task Manager view.
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
      file_id: File.id,
      to_storage_id: Storage.id,
      network_id: Network.id,
      connection_type: :ftp | :public_ftp,
      type: :download | :upload
    }

    @enforce_keys [
      :entity_id,
      :to_server_id,
      :from_server_id,
      :file_id,
      :to_storage_id,
      :network_id,
      :connection_type,
      :type
    ]
    defstruct [
      :entity_id,
      :to_server_id,
      :from_server_id,
      :file_id,
      :to_storage_id,
      :network_id,
      :connection_type,
      :type
    ]
  end

  defmodule Aborted do
    @moduledoc """
    FileTransferAborted represents the moment a FileTransferProcess was aborted.

    Useful mostly to notify the Client of the change.
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
      file_id: File.id,
      to_storage_id: Storage.id,
      network_id: Network.id,
      connection_type: :ftp | :public_ftp,
      type: :download | :upload,
      reason: :file_deleted | :cancelled
    }

    @enforce_keys [
      :entity_id,
      :to_server_id,
      :from_server_id,
      :file_id,
      :to_storage_id,
      :network_id,
      :connection_type,
      :type,
      :reason
    ]
    defstruct [
      :entity_id,
      :to_server_id,
      :from_server_id,
      :file_id,
      :to_storage_id,
      :network_id,
      :connection_type,
      :type,
      :reason
    ]
  end
end
