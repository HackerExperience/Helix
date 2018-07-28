defmodule Helix.Network.Event.ConnectionTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Log.Macros

  alias Helix.Log.Query.Log, as: LogQuery

  alias Helix.Test.Event.Helper, as: EventHelper
  alias Helix.Test.Event.Setup, as: EventSetup
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Network.Setup, as: NetworkSetup

  describe "event reactions" do
    test "new log is created when ssh connection is started (no bounce)" do
      {connection, _} = NetworkSetup.connection(type: :ssh)
      event = EventSetup.Network.connection_started(connection)

      EventHelper.emit(event)

      entity_id = ServerHelper.get_owner(event.tunnel.gateway_id).entity_id

      gateway_ip = ServerHelper.get_ip(event.tunnel.gateway_id)
      target_ip = ServerHelper.get_ip(event.tunnel.target_id)

      [log_source] = LogQuery.get_logs_on_server(event.tunnel.gateway_id)
      assert_log log_source, event.tunnel.gateway_id, entity_id,
        :remote_login_gateway, %{ip: target_ip}

      [log_target] = LogQuery.get_logs_on_server(event.tunnel.target_id)
      assert_log log_target, event.tunnel.target_id, entity_id,
        :remote_login_endpoint, %{ip: gateway_ip}
    end

    test "new log is created when ssh connection is started (with bounce)" do
      {connection, _} = NetworkSetup.connection(type: :ssh)
      {bounce, _} = NetworkSetup.Bounce.bounce()

      NetworkHelper.set_bounce(connection, bounce.bounce_id)

      event = EventSetup.Network.connection_started(connection)

      EventHelper.emit(event)

      entity_id = ServerHelper.get_owner(event.tunnel.gateway_id).entity_id

      # First log does not contain the target ip (it uses the bounce ip instead)
      [log_source] = LogQuery.get_logs_on_server(event.tunnel.gateway_id)
      assert_log log_source, event.tunnel.gateway_id, entity_id,
        :remote_login_gateway, %{}

      assert_bounce \
        bounce, event.tunnel.gateway_id, event.tunnel.target_id, entity_id

      # Last log does not contain the source ip (it uses the bounce ip instead)
      [log_target] = LogQuery.get_logs_on_server(event.tunnel.target_id)
      assert_log log_target, event.tunnel.target_id, entity_id,
        :remote_login_endpoint, %{}
    end
  end
end
