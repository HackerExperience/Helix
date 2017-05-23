defmodule Helix.Software.Model.SoftwareType.Firewall do
  @moduledoc false

  defmodule FirewallStarted do
    @moduledoc false

    @enforce_keys [:version, :gateway_id]
    defstruct [:version, :gateway_id]
  end

  defmodule FirewallStopped do
    @moduledoc false

    @enforce_keys [:version, :gateway_id]
    defstruct [:version, :gateway_id]
  end
end
