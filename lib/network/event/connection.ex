defmodule Helix.Network.Event.Connection do

  import Helix.Event

  event Started do
    @moduledoc false

    alias Helix.Entity.Query.Entity, as: EntityQuery
    alias Helix.Network.Model.Connection
    alias Helix.Network.Model.Tunnel
    alias Helix.Network.Repo

    @type t :: %__MODULE__{
      connection: Connection.t,
      tunnel: Tunnel.t,
      type: Connection.type
    }

    event_struct [:connection, :tunnel, :type]

    @spec new(Connection.t) ::
      t
    def new(connection = %Connection{}) do
      connection = Repo.preload(connection, :tunnel)

      %__MODULE__{
        connection: connection,
        tunnel: connection.tunnel,
        type: connection.connection_type
      }
    end

    loggable do

      log(event = %__MODULE__{type: :ssh}) do
        gateway_id = event.tunnel.gateway_id
        destination_id = event.tunnel.destination_id

        entity = EntityQuery.fetch_by_server(gateway_id)

        ip_source = get_ip(gateway_id, event.tunnel.network_id)
        ip_target = get_ip(destination_id, event.tunnel.network_id)

        msg_source = "localhost logged into #{ip_target}"
        msg_target = "#{ip_source} logged in as root"

        log_source = build_entry(gateway_id, entity.entity_id, msg_source)
        log_target = build_entry(destination_id, entity.entity_id, msg_target)

        [log_source, log_target]
      end
    end
  end

  event Closed do
    @moduledoc false

    alias Helix.Network.Model.Connection
    alias Helix.Network.Model.Tunnel
    alias Helix.Network.Repo

    @type t :: %__MODULE__{
      connection: Connection.t,
      tunnel: Tunnel.t,
      type: Connection.type,
      reason: Connection.close_reasons
    }

    event_struct [:connection, :tunnel, :type, :reason]

    @spec new(Connection.t, Connection.close_reasons) ::
      t
    def new(connection = %Connection{}, reason \\ :normal) do
      connection = Repo.preload(connection, :tunnel)

      %__MODULE__{
        connection: connection,
        tunnel: connection.tunnel,
        reason: reason,
        type: connection.connection_type
      }
    end
  end
end
