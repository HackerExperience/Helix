defmodule Helix.Software.Event.File.DownloadedTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Log.Macros

  alias Helix.Event
  alias Helix.Log.Query.Log, as: LogQuery

  alias Helix.Test.Event.Setup, as: EventSetup
  alias Helix.Test.Log.Helper, as: LogHelper
  alias Helix.Test.Server.Helper, as: ServerHelper

  describe "event reactions" do
    # Context: gateway is downloading from destination
    test "new log is created (non-public ftp download)" do
      event = EventSetup.Software.file_downloaded()

      # Simulates the Event being dispatched to the listening handlers
      Event.emit(event)

      file_name = LogHelper.log_file_name(event.file)
      gateway_ip = ServerHelper.get_ip(event.to_server_id)
      destination_ip = ServerHelper.get_ip(event.from_server_id)

      # Log saved on transfer source
      [log_gateway] = LogQuery.get_logs_on_server(event.to_server_id)
      assert_log log_gateway, event.to_server_id, event.entity_id,
        :file_download_gateway, %{file_name: file_name, ip: destination_ip}

      # Log saved on transfer target
      [log_destination] = LogQuery.get_logs_on_server(event.from_server_id)
      assert_log log_destination, event.from_server_id, event.entity_id,
        :file_download_endpoint, %{file_name: file_name, ip: gateway_ip}
    end

    # Context: gateway is downloading from destination
    test "new log is created (PFTP download)" do
      event = EventSetup.Software.file_downloaded(connection_type: :public_ftp)

      # Simulates the Event being dispatched to the listening handlers
      Event.emit(event)

      file_name = LogHelper.log_file_name(event.file)
      gateway_ip = ServerHelper.get_ip(event.to_server_id) |> censor_ip
      destination_ip = ServerHelper.get_ip(event.from_server_id)

      # Log saved on transfer source (gateway)
      [log_gateway] = LogQuery.get_logs_on_server(event.to_server_id)
      assert_log log_gateway, event.to_server_id, event.entity_id,
        :pftp_file_download_gateway, %{file_name: file_name, ip: destination_ip}

      # Log saved on transfer target
      [log_destination] = LogQuery.get_logs_on_server(event.from_server_id)
      assert_log log_destination, event.from_server_id, event.entity_id,
        :pftp_file_download_endpoint, %{file_name: file_name, ip: gateway_ip}
    end
  end
end
