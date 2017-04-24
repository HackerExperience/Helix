defmodule Helix.Software.Model.SoftwareType.Cracker.ProcessConclusionEvent do

  @enforce_keys [:entity_id, :network_id, :server_ip, :server_id, :server_type]
  defstruct [:entity_id, :network_id, :server_ip, :server_id, :server_type]
end
