defmodule Helix.Software.Event.File.DownloadedTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Log.Macros

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
      assert_log \
        log_source,
        event.from_server_id,
        event.entity_id,
        "localhost downloaded",
        contains: transfer_to_ip,
        reject: transfer_from_ip

      # Log saved on transfer target
      [log_target] = LogQuery.get_logs_on_server(event.to_server_id)
      assert_log \
        log_target,
        event.to_server_id,
        event.entity_id,
        "at localhost",
        contains: transfer_from_ip,
        rejects: transfer_to_ip
    end
  end
end
