defmodule Helix.Software.Event.LogForge.LogEdit do

  import Helix.Event

  event Processed do

    alias Helix.Entity.Model.Entity
    alias Helix.Log.Model.Log
    alias Helix.Software.Model.SoftwareType.LogForge, as: LogForgeProcess

    @type t :: %__MODULE__{
      target_log_id: Log.id,
      entity_id: Entity.id,
      message: String.t,
      version: pos_integer
    }

    event_struct [:target_log_id, :entity_id, :message, :version]

    @spec new(LogForgeProcess.t) ::
      t
    def new(data = %LogForgeProcess{operation: :edit}) do
      %__MODULE__{
        target_log_id: data.target_log_id,
        entity_id: data.entity_id,
        message: data.message,
        version: data.version
      }
    end
  end
end
