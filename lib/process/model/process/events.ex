defmodule Helix.Process.Model.Process.ProcessCreatedEvent do
  @moduledoc false

  @enforce_keys [:process_id, :gateway_id]
  defstruct [:process_id, :gateway_id]
end
