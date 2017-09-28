defmodule Helix.Software.Event.File.Transfer do

  defmodule Processed do

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
end
