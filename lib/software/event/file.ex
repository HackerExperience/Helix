defmodule Helix.Software.Event.File do

  defmodule Downloaded do

    alias Helix.Entity.Model.Entity
    alias Helix.Network.Model.Network
    alias Helix.Server.Model.Server
    alias Helix.Software.Model.File
    alias Helix.Software.Model.Storage

    @type t :: %{
      entity_id: Entity.id,
      to_server_id: Server.id,
      from_server_id: Server.id,
      file_id: File.id,
      to_storage_id: Storage.id,
      network_id: Network.id,
      connection_type: :ftp | :public_ftp
    }

    @enforce_keys [
      :entity_id,
      :to_server_id,
      :from_server_id,
      :file_id,
      :network_id,
      :connection_type
    ]
    defstruct [
      :entity_id,
      :to_server_id,
      :from_server_id,
      :file_id,
      :to_storage_id,
      :network_id,
      :connection_type
    ]
  end

  defmodule DownloadFailed do

    alias Helix.Entity.Model.Entity
    alias Helix.Network.Model.Network
    alias Helix.Server.Model.Server
    alias Helix.Software.Model.Storage

    @type reason ::
      :no_space_left
      | :file_not_found
      | :unknown

    @type t :: %{
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

    alias Helix.Entity.Model.Entity
    alias Helix.Network.Model.Network
    alias Helix.Server.Model.Server
    alias Helix.Software.Model.File
    alias Helix.Software.Model.Storage

    @type t :: %{
      entity_id: Entity.id,
      to_server_id: Server.id,
      from_server_id: Server.id,
      file_id: File.id,
      to_storage_id: Storage.id,
      network_id: Network.id
    }

    @enforce_keys [
      :entity_id,
      :to_server_id,
      :from_server_id,
      :file_id,
      :network_id
    ]
    defstruct [
      :entity_id,
      :to_server_id,
      :from_server_id,
      :file_id,
      :to_storage_id,
      :network_id
    ]
  end

  defmodule UploadFailed do

    alias Helix.Entity.Model.Entity
    alias Helix.Network.Model.Network
    alias Helix.Server.Model.Server
    alias Helix.Software.Model.Storage

    @type reason ::
      :no_space_left
      | :file_not_found
      | :unknown

    @type t :: %{
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

  defmodule Aborted do
  end
end
