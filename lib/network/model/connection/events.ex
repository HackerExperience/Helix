defmodule Helix.Network.Model.Connection.ConnectionStartedEvent do
  @moduledoc false

  alias Helix.Network.Model.Connection
  alias Helix.Network.Model.Network
  alias Helix.Network.Model.Tunnel

  @type t :: %__MODULE__{
    connection_id: Connection.id,
    tunnel_id: Tunnel.id,
    network_id: Network.id,
    connection_type: Connection.type
  }

  @enforce_keys [:connection_id, :tunnel_id, :network_id, :connection_type]
  defstruct [:connection_id, :tunnel_id, :network_id, :connection_type]
end

defmodule Helix.Network.Model.Connection.ConnectionClosedEvent do
  @moduledoc false

  alias HELL.Constant
  alias Helix.Network.Model.Connection
  alias Helix.Network.Model.Network
  alias Helix.Network.Model.Tunnel

  @type t :: %__MODULE__{
    connection_id: Connection.id,
    tunnel_id: Tunnel.id,
    network_id: Network.id,
    meta: Connection.meta,
    connection_type: Connection.type,
    reason: Constant.t
  }

  @enforce_keys ~w/
    connection_id
    tunnel_id
    network_id
    meta
    connection_type
    reason/a
  defstruct ~w/
    connection_id
    tunnel_id
    network_id
    meta
    connection_type
    reason/a
end
