defmodule Helix.Log.Event.Handler.LogTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Log.Macros

  alias Helix.Event
  alias Helix.Software.Event.LogForge.LogEdit.Processed,
    as: LogForgeEditComplete
  alias Helix.Software.Event.LogForge.LogCreate.Processed,
    as: LogForgeCreateComplete
  alias Helix.Log.Event.Handler.Log, as: LogHandler
  alias Helix.Log.Query.Log, as: LogQuery
  alias Helix.Log.Repo

  alias Helix.Test.Event.Setup, as: EventSetup
  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Network.Setup, as: NetworkSetup
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Log.Factory, as: LogFactory

  describe "handle_event/1" do
    test "follows the LoggableFlow" do
      # NOTE: We are using `FileDownloadedEvent` merely as a sample to make sure
      # the LogHandler works as expected, this is not the place to test that
      # EventX is correctly generating log entries. This should be tested
      # elsewhere. That's why this same test also exists on
      # FileDownloadedEventTest
      event = EventSetup.Software.file_downloaded()

      # Simulates the handler receiving the event
      assert :ok == LogHandler.handle_event(event)

      # Now we verify that the corresponding log has been saved on the relevant
      # places.
      [log_gateway] = LogQuery.get_logs_on_server(event.to_server_id)
      assert_log \
        log_gateway,
        event.to_server_id,
        event.entity_id,
        "localhost downloaded"

      [log_destination] = LogQuery.get_logs_on_server(event.from_server_id)
      assert_log \
        log_destination,
        event.from_server_id,
        event.entity_id,
        "from localhost"
    end

    test "creates logs on intermediary nodes (bounces)" do
      {bounce, _} = NetworkSetup.Bounce.bounce(total: 4)
      [
        {l1_server_id, _, l1_ip},
        {l2_server_id, _, l2_ip},
        {l3_server_id, _, l3_ip},
        {l4_server_id, _, l4_ip},
      ] = bounce.links

      event =
        EventSetup.Software.file_downloaded()
        |> Event.set_bounce(bounce)

      gateway_ip = ServerHelper.get_ip(event.to_server_id)
      endpoint_ip = ServerHelper.get_ip(event.from_server_id)

      # Simulates the handler receiving the event
      assert :ok == LogHandler.handle_event(event)

      # Now we verify that the corresponding log has been saved on the relevant
      # places.
      [log_gateway] = LogQuery.get_logs_on_server(event.to_server_id)
      assert_log \
        log_gateway, event.to_server_id, event.entity_id, "localhost downloaded"

      # log on `l1` tells connection was bounced from `gateway` to `l2`
      [log_bounce1] = LogQuery.get_logs_on_server(l1_server_id)
      assert_log \
        log_bounce1, l1_server_id, event.entity_id,
        "Connection bounced", contains: "from #{gateway_ip} to #{l2_ip}"

      # log on `l2` tells connection was bounced from `l1` to `l3`
      [log_bounce2] = LogQuery.get_logs_on_server(l2_server_id)
      assert_log \
        log_bounce2, l2_server_id, event.entity_id,
          "Connection bounced", contains: "from #{l1_ip} to #{l3_ip}"

      # log on `l3` tells connection was bounced from `l2` to `l4`
      [log_bounce3] = LogQuery.get_logs_on_server(l3_server_id)
      assert_log \
        log_bounce3, l3_server_id, event.entity_id,
          "Connection bounced", contains: "from #{l2_ip} to #{l4_ip}"

      # log on `l4` tells connection was bounced from `l3` to `endpoint`
      [log_bounce4] = LogQuery.get_logs_on_server(l4_server_id)
      assert_log \
        log_bounce4, l4_server_id, event.entity_id,
          "Connection bounced", contains: "from #{l3_ip} to #{endpoint_ip}"

      [log_destination] = LogQuery.get_logs_on_server(event.from_server_id)
      assert_log \
        log_destination, event.from_server_id, event.entity_id, "from localhost"
    end

    test "works on single-node log ('offline log')" do
      # Scenario: `ServerJoinedEvent` (on `local` join) only generates log on
      # the local server.
      # NOTE: This is mostly testing the `log` macro on this custom behaviour
      event = EventSetup.Server.joined(:local)

      # Simulates the handler receiving the event
      assert :ok == LogHandler.handle_event(event)

      [log_server] = LogQuery.get_logs_on_server(event.server_id)
      assert_log \
        log_server, event.server_id, event.entity_id,
        "Localhost logged in"
    end
  end

  describe "log_forge_conclusion/1 for LogForge.Edit" do
    test "adds revision to target log" do
      target_log = LogFactory.insert(:log)
      {entity, _} = EntitySetup.entity()
      message = "I just got hidden"

      event = %LogForgeEditComplete{
        target_log_id: target_log.log_id,
        entity_id: entity.entity_id,
        message: message,
        version: 100
      }

      revisions_before = LogQuery.count_revisions_of_entity(target_log, entity)
      LogHandler.log_forge_conclusion(event)
      revisions_after = LogQuery.count_revisions_of_entity(target_log, entity)
      target_log = LogQuery.fetch(target_log.log_id)

      assert revisions_after == revisions_before + 1
      assert message == target_log.message
    end
  end

  describe "log_forge_conclusion/1 for LogForge.Create" do
    test "creates specified log on target server" do
      {server, %{entity: entity}} = ServerSetup.server()

      message = "Mess with the best, die like the rest"

      event = %LogForgeCreateComplete{
        entity_id: entity.entity_id,
        target_id: server.server_id,
        message: message,
        version: 456
      }

      LogHandler.log_forge_conclusion(event)

      assert [log] = LogQuery.get_logs_on_server(server)
      assert [%{forge_version: 456}] = Repo.preload(log, :revisions).revisions
    end
  end
end
