defmodule Helix.Event.Loggable.FlowTest do

  use Helix.Test.Case.Integration

  alias Helix.Log.Query.Log, as: LogQuery
  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Server
  alias Helix.Event.Loggable.Flow, as: LoggableFlow

  alias Helix.Test.Server.Setup, as: ServerSetup

  describe "get_ip/2" do
    test "returns empty string if not found " do
      ip = LoggableFlow.get_ip(Server.ID.generate(), Network.ID.generate())
      assert is_binary(ip)
    end
  end

  describe "save/1" do
    test "logs are saved" do
      {server, %{entity: entity}} = ServerSetup.server()

      msg = "foobar"
      entry = LoggableFlow.build_entry(server.server_id, entity.entity_id, msg)

      assert :ok == LoggableFlow.save(entry)

      [log] = LogQuery.get_logs_on_server(server)
      assert log.message == msg
      assert log.entity_id == entity.entity_id
      assert log.server_id == server.server_id
    end

    test "performs a noop on empty list" do
      assert :ok == LoggableFlow.save([])
    end
  end
end
