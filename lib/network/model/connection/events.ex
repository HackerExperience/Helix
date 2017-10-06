defmodule Helix.Network.Model.Connection.ConnectionStartedEvent do
  @moduledoc false

  import Helix.Log.Loggable.Flow

  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Network.Model.Connection
  alias Helix.Network.Model.Network
  alias Helix.Network.Model.Tunnel

  @type t :: %__MODULE__{
    connection_id: Connection.id,
    tunnel: Tunnel.t,
    network_id: Network.id,
    connection_type: Connection.type
  }

  @enforce_keys [:connection_id, :tunnel, :network_id, :connection_type]
  defstruct [:connection_id, :tunnel, :network_id, :connection_type]

  log(event = %__MODULE__{connection_type: :ssh}) do
    gateway_id = event.tunnel.gateway_id
    destination_id = event.tunnel.destination_id

    entity = EntityQuery.fetch_by_server(gateway_id)

    ip_source = get_ip(gateway_id, event.network_id)
    ip_target = get_ip(destination_id, event.network_id)

    msg_source = "localhost logged into #{ip_target}"
    msg_target = "#{ip_source} logged in as root"

    log_source = build_entry(gateway_id, entity.entity_id, msg_source)
    log_target = build_entry(destination_id, entity.entity_id, msg_target)

    [log_source, log_target]
  end
end

defmodule Helix.Network.Model.Connection.ConnectionClosedEvent do
  @moduledoc false

  alias HELL.Constant
  alias Helix.Network.Model.Connection
  alias Helix.Network.Model.Network
  alias Helix.Network.Model.Tunnel

  @type t :: %__MODULE__{
    connection_id: Connection.id,
    tunnel: Tunnel.t,
    network_id: Network.id,
    meta: Connection.meta,
    connection_type: Connection.type,
    reason: Constant.t
  }

  @enforce_keys ~w/
    connection_id
    tunnel
    network_id
    meta
    connection_type
    reason/a
  defstruct ~w/
    connection_id
    tunnel
    network_id
    meta
    connection_type
    reason/a
end
