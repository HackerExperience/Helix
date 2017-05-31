defmodule Helix.Software.Model.SoftwareType.LogForge.ProcessConclusionEvent do
  @moduledoc false

  @enforce_keys [:target_log_id, :version, :message, :entity_id]
  defstruct [:target_log_id, :version, :message, :entity_id]
end
