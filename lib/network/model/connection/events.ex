defmodule Helix.Network.Model.Connection.ConnectionStartedEvent do
  @moduledoc false

  @enforce_keys [:connection_id, :tunnel_id, :network_id]
  defstruct [:connection_id, :tunnel_id, :network_id]
end

defmodule Helix.Network.Model.ConnectionClosedEvent do
  @moduledoc false

  @enforce_keys [:connection_id, :tunnel_id, :network_id, :reason]
  defstruct [:connection_id, :tunnel_id, :network_id, :reason]
end
