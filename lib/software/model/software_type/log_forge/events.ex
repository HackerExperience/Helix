defmodule Helix.Software.Model.SoftwareType.LogForge.ProcessConclusionEvent do

  alias Helix.Entity.Model.Entity
  alias Helix.Log.Model.Log

  @type t :: %__MODULE__{
    target_log_id: Log.id,
    entity_id: Entity.id,
    message: String.t,
    version: pos_integer
  }

  @enforce_keys [:target_log_id, :entity_id, :message, :version]
  defstruct [:target_log_id, :entity_id, :message, :version]
end
