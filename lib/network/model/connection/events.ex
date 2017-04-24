defmodule Helix.Network.Model.Connection.ConnectionStartedEvent do
  @moduledoc false

  @enforce_keys [:connection_id, :tunnel_id, :network_id, :connection_type]
  defstruct [:connection_id, :tunnel_id, :network_id, :connection_type]
end

defmodule Helix.Network.Model.Connection.ConnectionClosedEvent do
  @moduledoc false

  @enforce_keys [:connection_id, :tunnel_id, :network_id, :reason]
  defstruct [:connection_id, :tunnel_id, :network_id, :reason]
end
