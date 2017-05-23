defmodule Helix.Software.Model.SoftwareType.LogDeleter.ProcessConclusionEvent do
  @moduledoc false

  @enforce_keys [:target_log_id]
  defstruct [:target_log_id]
end
