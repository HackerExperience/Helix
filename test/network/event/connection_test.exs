defmodule Helix.Network.Event.ConnectionTest do

  use Helix.Test.Case.Integration

  alias Helix.Event
  alias Helix.Log.Query.Log, as: LogQuery

  alias Helix.Test.Event.Setup, as: EventSetup
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Network.Setup, as: NetworkSetup

  describe "event reactions" do
    test "new log is created when ssh connection is started" do
      {connection, _} = NetworkSetup.connection(type: :ssh)
      event = EventSetup.Network.connection_started(connection)

      Event.emit(event)

      entity_id = ServerHelper.get_owner(event.tunnel.gateway_id).entity_id

      gateway_ip = ServerHelper.get_ip(event.tunnel.gateway_id)
      destination_ip = ServerHelper.get_ip(event.tunnel.destination_id)

      [log_source] = LogQuery.get_logs_on_server(event.tunnel.gateway_id)
      assert log_source.server_id == event.tunnel.gateway_id
      assert log_source.entity_id == entity_id
      assert log_source.message =~ "localhost logged into"
      assert log_source.message =~ destination_ip

      [log_target] = LogQuery.get_logs_on_server(event.tunnel.destination_id)
      assert log_target.server_id == event.tunnel.destination_id
      assert log_target.entity_id == entity_id
      assert log_target.message =~ "logged in as"
      assert log_target.message =~ gateway_ip
    end
  end

end
