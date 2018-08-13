defmodule Helix.Event.Loggable.FlowTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Macros

  alias Helix.Log.Query.Log, as: LogQuery
  alias Helix.Event.Loggable.Flow, as: LoggableFlow

  alias Helix.Test.Entity.Helper, as: EntityHelper
  alias Helix.Test.Log.Helper, as: LogHelper
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Network.Setup, as: NetworkSetup
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Server.Setup, as: ServerSetup

  describe "get_ip/2" do
    test "returns empty string if not found " do
      ip = LoggableFlow.get_ip(ServerHelper.id(), NetworkHelper.id())
      assert is_binary(ip)
    end
  end

  describe "build_bounce_entries/5" do
    test "creates bounce log entries in the correct order" do
      entity_id = EntityHelper.id()

      network_id = NetworkHelper.internet_id()

      gateway = {ServerHelper.id(), network_id, "1.2.3.4"}
      link1 = {ServerHelper.id(), network_id, "1.1.1.1"}
      link2 = {ServerHelper.id(), network_id, "1.1.1.2"}
      link3 = {ServerHelper.id(), network_id, "1.1.1.3"}
      target = {ServerHelper.id(), network_id, "4.3.2.1"}

      {bounce, _} = NetworkSetup.Bounce.bounce(links: [link1, link2, link3])

      [entry1, entry2, entry3] =
        LoggableFlow.build_bounce_entries(
          bounce, gateway, target, entity_id, network_id
        )

      # `link1` says bounce comes from `gateway` and goes to `link2`
      assert elem(entry1, 0) == elem(link1, 0)
      assert elem(entry1, 1) == entity_id
      {log_type, log_data} = elem(entry1, 2)
      assert log_type == :connection_bounced
      assert log_data.ip_prev == "1.2.3.4"
      assert log_data.ip_next == "1.1.1.2"
      assert log_data.network_id == network_id

      # `link2` says bounce comes from `link1` and goes to `link3`
      assert elem(entry2, 0) == elem(link2, 0)
      assert elem(entry2, 1) == entity_id
      {log_type, log_data} = elem(entry2, 2)
      assert log_type == :connection_bounced
      assert log_data.ip_prev == "1.1.1.1"
      assert log_data.ip_next == "1.1.1.3"
      assert log_data.network_id == network_id

      # `link3` says bounce comes from `link2` and goes to `target`
      assert elem(entry3, 0) == elem(link3, 0)
      assert elem(entry3, 1) == entity_id
      {log_type, log_data} = elem(entry3, 2)
      assert log_type == :connection_bounced
      assert log_data.ip_prev == "1.1.1.2"
      assert log_data.ip_next == "4.3.2.1"
      assert log_data.network_id == network_id
    end
  end

  describe "save/1" do
    test "logs are saved" do
      {server, %{entity: entity}} = ServerSetup.server()

      log_info = {log_type, log_data} = LogHelper.log_info()

      entry =
        LoggableFlow.build_entry(server.server_id, entity.entity_id, log_info)

      # Saves the entry; returns LogCreatedEvent
      assert [event] = LoggableFlow.save(entry)
      assert event.__struct__ == Helix.Log.Event.Log.Created

      # Log is stored correctly on the server
      [log] = LogQuery.get_logs_on_server(server)
      assert log.server_id == server.server_id
      assert log.revision.entity_id == entity.entity_id
      assert log.revision.type == log_type
      assert_map_str log.revision.data, Map.from_struct(log_data)
    end

    test "performs a noop on empty list" do
      assert [] == LoggableFlow.save([])
    end
  end
end
