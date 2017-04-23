defmodule Helix.Software.Model.SoftwareType.Cracker.ProcessConclusionEvent do

  @enforce_keys [:entity_id, :network_id, :server_ip, :server_id]
  defstruct [:entity_id, :network_id, :server_ip, :server_id]
end
