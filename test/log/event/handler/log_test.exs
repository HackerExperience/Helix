defmodule Helix.Log.Event.Handler.LogTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Log.Macros

  alias Helix.Software.Event.LogForge.LogEdit.Processed,
    as: LogForgeEditComplete
  alias Helix.Software.Event.LogForge.LogCreate.Processed,
    as: LogForgeCreateComplete
  alias Helix.Log.Event.Handler.Log, as: LogHandler
  alias Helix.Log.Query.Log, as: LogQuery
  alias Helix.Log.Repo

  alias Helix.Test.Event.Setup, as: EventSetup
  alias Helix.Test.Entity.Factory, as: EntityFactory
  alias Helix.Test.Server.Factory, as: ServerFactory
  alias Helix.Test.Log.Factory, as: LogFactory

  describe "handle_event/1" do
    test "follows the LoggableFlow" do
      # Note: We are using `FileDownloadedEvent` merely as a sample to make sure
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
  end

  describe "log_forge_conclusion/1 for LogForge.Edit" do
    test "adds revision to target log" do
      target_log = LogFactory.insert(:log)
      entity = EntityFactory.insert(:entity)
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
      entity = EntityFactory.insert(:entity)
      server = ServerFactory.insert(:server)
      message = "Mess with the best, die like the rest"

      event = %LogForgeCreateComplete{
        entity_id: entity.entity_id,
        target_server_id: server.server_id,
        message: message,
        version: 456
      }

      LogHandler.log_forge_conclusion(event)

      assert [log] = LogQuery.get_logs_on_server(server)
      assert [%{forge_version: 456}] = Repo.preload(log, :revisions).revisions
    end
  end
end
