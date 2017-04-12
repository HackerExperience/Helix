defmodule Helix.Process.Model.Process.ProcessCreatedEvent do
  @moduledoc false

  @enforce_keys [:process_id, :gateway_id, :target_id]
  defstruct [:process_id, :gateway_id, :target_id]
end

defmodule Helix.Process.Model.Process.ProcessConclusionEvent do
  @moduledoc false

  # This event is used solely to update the TOP display on the client
  @enforce_keys [:gateway_id, :target_id]
  defstruct [:gateway_id, :target_id]
end
