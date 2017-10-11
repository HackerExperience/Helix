defmodule Helix.Software.Event.File.Transfer do

  import Helix.Event

  event Processed do
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
    alias Helix.Process.Model.Process
    alias Helix.Server.Model.Server
    alias Helix.Software.Model.File
    alias Helix.Software.Model.Storage
    alias Helix.Software.Process.File.Transfer, as: FileTransferProcess

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

    event_struct [
      :entity_id,
      :to_server_id,
      :from_server_id,
      :file_id,
      :to_storage_id,
      :network_id,
      :connection_type,
      :type
    ]

    @spec new(Process.t, FileTransferProcess.t, Server.id, Server.id) ::
      t
    def new(
      process = %Process{},
      data = %FileTransferProcess{},
      from_server_id = %Server.ID{},
      to_server_id = %Server.ID{})
    do
      %__MODULE__{
        entity_id: process.source_entity_id,
        to_server_id: to_server_id,
        from_server_id: from_server_id,
        file_id: process.file_id,
        network_id: process.network_id,
        to_storage_id: data.destination_storage_id,
        connection_type: data.connection_type,
        type: data.type
      }
    end
  end

  event Aborted do
    @moduledoc """
    FileTransferAborted represents the moment a FileTransferProcess was aborted.

    Useful mostly to notify the Client of the change.
    """

    alias Helix.Entity.Model.Entity
    alias Helix.Network.Model.Network
    alias Helix.Process.Model.Process
    alias Helix.Server.Model.Server
    alias Helix.Software.Model.File
    alias Helix.Software.Model.Storage
    alias Helix.Software.Process.File.Transfer, as: FileTransferProcess

    @type t :: %__MODULE__{
      entity_id: Entity.id,
      to_server_id: Server.id,
      from_server_id: Server.id,
      file_id: File.id,
      to_storage_id: Storage.id,
      network_id: Network.id,
      connection_type: :ftp | :public_ftp,
      type: :download | :upload,
      reason: reason
    }

    @type reason :: :killed

    event_struct [
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

    @spec new(Process.t, FileTransferProcess.t, Server.id, Server.id, reason) ::
      t
    def new(
      process = %Process{},
      data = %FileTransferProcess{},
      from_server_id = %Server.ID{},
      to_server_id = %Server.ID{},
      reason)
    do
      %__MODULE__{
        entity_id: process.source_entity_id,
        to_server_id: to_server_id,
        from_server_id: from_server_id,
        file_id: process.file_id,
        network_id: process.network_id,
        to_storage_id: data.destination_storage_id,
        connection_type: data.connection_type,
        type: data.type,
        reason: reason
      }
    end
  end
end
