defmodule Helix.Software.Model.SoftwareType.Firewall.FirewallStartedEvent do
  @moduledoc false

  @enforce_keys [:version, :gateway_id]
  defstruct [:version, :gateway_id]
end

defmodule Helix.Software.Model.SoftwareType.Firewall.FirewallStoppedEvent do
  @moduledoc false

  @enforce_keys [:version, :gateway_id]
  defstruct [:version, :gateway_id]
end
