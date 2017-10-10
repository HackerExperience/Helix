defmodule Helix.Software.Event.LogForge.LogCreate do

  import Helix.Event

  event Processed do

    alias Helix.Entity.Model.Entity
    alias Helix.Server.Model.Server
    alias Helix.Software.Model.SoftwareType.LogForge, as: LogForgeProcess

    @type t :: %__MODULE__{
      target_server_id: Server.id,
      entity_id: Entity.id,
      message: String.t,
      version: pos_integer
    }

    event_struct [:target_server_id, :entity_id, :message, :version]

    @spec new(LogForgeProcess.t) ::
      t
    def new(data = %LogForgeProcess{operation: :create}) do
      %__MODULE__{
        target_server_id: data.target_server_id,
        entity_id: data.entity_id,
        message: data.message,
        version: data.version
      }
    end
  end
end
