defmodule Helix.Software.Event.File.DownloadedTest do

  use Helix.Test.Case.Integration

  alias Helix.Event
  alias Helix.Log.Query.Log, as: LogQuery

  alias Helix.Test.Event.Setup, as: EventSetup
  alias Helix.Test.Server.Helper, as: ServerHelper

  describe "event reactions" do
    test "new log is created" do
      event = EventSetup.Software.file_downloaded()

      # Simulates the Event being dispatched to the listening handlers
      Event.emit(event)

      transfer_from_ip = ServerHelper.get_ip(event.from_server_id)
      transfer_to_ip = ServerHelper.get_ip(event.to_server_id)

      # Log saved on transfer source
      [log_source] = LogQuery.get_logs_on_server(event.from_server_id)
      assert log_source.server_id == event.from_server_id
      assert log_source.entity_id == event.entity_id
      assert log_source.message =~ "localhost downloaded"
      assert log_source.message =~ transfer_to_ip

      # Log saved on transfer target
      [log_target] = LogQuery.get_logs_on_server(event.to_server_id)
      assert log_target.server_id == event.to_server_id
      assert log_target.entity_id == event.entity_id
      assert log_target.message =~ "at localhost"
      assert log_target.message =~ transfer_from_ip
    end
  end
end
