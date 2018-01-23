defmodule Helix.Network.Event.ConnectionTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Log.Macros

  alias Helix.Log.Query.Log, as: LogQuery

  alias Helix.Test.Event.Helper, as: EventHelper
  alias Helix.Test.Event.Setup, as: EventSetup
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Network.Setup, as: NetworkSetup

  describe "event reactions" do
    test "new log is created when ssh connection is started" do
      {connection, _} = NetworkSetup.connection(type: :ssh)
      event = EventSetup.Network.connection_started(connection)

      EventHelper.emit(event)

      entity_id = ServerHelper.get_owner(event.tunnel.gateway_id).entity_id

      gateway_ip = ServerHelper.get_ip(event.tunnel.gateway_id)
      target_ip = ServerHelper.get_ip(event.tunnel.target_id)

      [log_source] = LogQuery.get_logs_on_server(event.tunnel.gateway_id)

      assert_log \
        log_source,
        event.tunnel.gateway_id,
        entity_id,
        "localhost logged into",
        contains: target_ip,
        reject: gateway_ip

      [log_target] = LogQuery.get_logs_on_server(event.tunnel.target_id)

      assert_log \
        log_target,
        event.tunnel.target_id,
        entity_id,
        "logged in as",
        contains: gateway_ip,
        reject: target_ip
    end
  end
end
