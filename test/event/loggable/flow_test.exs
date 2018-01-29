defmodule Helix.Event.Loggable.FlowTest do

  use Helix.Test.Case.Integration

  alias Helix.Log.Query.Log, as: LogQuery
  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Server
  alias Helix.Event.Loggable.Flow, as: LoggableFlow

  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Network.Setup, as: NetworkSetup
  alias Helix.Test.Server.Setup, as: ServerSetup

  describe "get_ip/2" do
    test "returns empty string if not found " do
      ip = LoggableFlow.get_ip(Server.ID.generate(), Network.ID.generate())
      assert is_binary(ip)
    end
  end

  describe "build_bounce_entries/2" do
    test "creates bounce log entries in the correct order" do
      entity_id = EntitySetup.id()

      gateway = {ServerSetup.id(), "::", "1.2.3.4"}
      link1 = {ServerSetup.id(), "::", "1.1.1.1"}
      link2 = {ServerSetup.id(), "::", "1.1.1.2"}
      link3 = {ServerSetup.id(), "::", "1.1.1.3"}
      target = {ServerSetup.id(), "::", "4.3.2.1"}

      {bounce, _} = NetworkSetup.Bounce.bounce(links: [link1, link2, link3])

      [entry1, entry2, entry3] =
        LoggableFlow.build_bounce_entries(bounce, gateway, target, entity_id)

      # `link1` says bounce comes from `gateway` and goes to `link2`
      assert elem(entry1, 0) == elem(link1, 0)
      assert elem(entry1, 1) == entity_id
      assert String.contains?(elem(entry1, 2), "from 1.2.3.4 to 1.1.1.2")

      # `link2` says bounce comes from `link1` and goes to `link3`
      assert elem(entry2, 0) == elem(link2, 0)
      assert elem(entry2, 1) == entity_id
      assert String.contains?(elem(entry2, 2), "from 1.1.1.1 to 1.1.1.3")

      # `link3` says bounce comes from `link2` and goes to `target`
      assert elem(entry3, 0) == elem(link3, 0)
      assert elem(entry3, 1) == entity_id
      assert String.contains?(elem(entry3, 2), "from 1.1.1.2 to 4.3.2.1")
    end
  end

  describe "save/1" do
    test "logs are saved" do
      {server, %{entity: entity}} = ServerSetup.server()

      msg = "foobar"
      entry = LoggableFlow.build_entry(server.server_id, entity.entity_id, msg)

      # Saves the entry; returns LogCreatedEvent
      assert [event] = LoggableFlow.save(entry)
      assert event.__struct__ == Helix.Log.Event.Log.Created

      [log] = LogQuery.get_logs_on_server(server)
      assert log.message == msg
      assert log.entity_id == entity.entity_id
      assert log.server_id == server.server_id
    end

    test "performs a noop on empty list" do
      assert [] == LoggableFlow.save([])
    end
  end
end
