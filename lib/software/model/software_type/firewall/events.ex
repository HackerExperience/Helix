defmodule Helix.Software.Model.SoftwareType.Firewall do
  @moduledoc false

  defmodule FirewallStartedEvent do
    @moduledoc false

    @enforce_keys [:version, :gateway_id]
    defstruct [:version, :gateway_id]
  end

  defmodule FirewallStoppedEvent do
    @moduledoc false

    @enforce_keys [:version, :gateway_id]
    defstruct [:version, :gateway_id]
  end
end
