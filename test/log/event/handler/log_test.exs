defmodule Helix.Log.Event.Handler.LogTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Macros
  import Helix.Test.Log.Macros

  alias Helix.Event
  alias Helix.Log.Event.Handler.Log, as: LogHandler
  alias Helix.Log.Query.Log, as: LogQuery
  alias Helix.Log.Repo

  alias Helix.Test.Event.Setup, as: EventSetup
  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Network.Setup, as: NetworkSetup
  alias Helix.Test.Process.Setup, as: ProcessSetup
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Log.Helper, as: LogHelper
  alias Helix.Test.Log.Setup, as: LogSetup

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

      file_name = LogHelper.log_file_name(event.file)

      # Now we verify that the corresponding log has been saved on the relevant
      # places.
      [log_gateway] = LogQuery.get_logs_on_server(event.to_server_id)
      assert_log log_gateway, event.to_server_id, event.entity_id,
        :file_download_gateway, %{file_name: file_name}

      [log_destination] = LogQuery.get_logs_on_server(event.from_server_id)
      assert_log log_destination, event.from_server_id, event.entity_id,
        :file_download_endpoint, %{file_name: file_name}
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

      file_name = LogHelper.log_file_name(event.file)

      gateway_ip = ServerHelper.get_ip(event.to_server_id)
      endpoint_ip = ServerHelper.get_ip(event.from_server_id)

      # Simulates the handler receiving the event
      assert :ok == LogHandler.handle_event(event)

      # Now we verify that the corresponding log has been saved on the relevant
      # places.
      [log_gateway] = LogQuery.get_logs_on_server(event.to_server_id)
      assert_log log_gateway, event.to_server_id, event.entity_id,
        :file_download_gateway, %{file_name: file_name, ip: l1_ip}

      # log on `l1` tells connection was bounced from `gateway` to `l2`
      [log_bounce1] = LogQuery.get_logs_on_server(l1_server_id)
      assert_log log_bounce1, l1_server_id, event.entity_id,
        :connection_bounced, %{ip_prev: gateway_ip, ip_next: l2_ip}

      # log on `l2` tells connection was bounced from `l1` to `l3`
      [log_bounce2] = LogQuery.get_logs_on_server(l2_server_id)
      assert_log log_bounce2, l2_server_id, event.entity_id,
          :connection_bounced, %{ip_prev: l1_ip, ip_next: l3_ip}

      # log on `l3` tells connection was bounced from `l2` to `l4`
      [log_bounce3] = LogQuery.get_logs_on_server(l3_server_id)
      assert_log log_bounce3, l3_server_id, event.entity_id,
          :connection_bounced, %{ip_prev: l2_ip, ip_next: l4_ip}

      # log on `l4` tells connection was bounced from `l3` to `endpoint`
      [log_bounce4] = LogQuery.get_logs_on_server(l4_server_id)
      assert_log log_bounce4, l4_server_id, event.entity_id,
          :connection_bounced, %{ip_prev: l3_ip, ip_next: endpoint_ip}

      [log_destination] = LogQuery.get_logs_on_server(event.from_server_id)
      assert_log log_destination, event.from_server_id, event.entity_id,
        :file_download_endpoint, %{file_name: file_name, ip: l4_ip}
    end

    test "works on single-node log ('offline log')" do
      # Scenario: `ServerJoinedEvent` (on `local` join) only generates log on
      # the local server.
      # NOTE: This is mostly testing the `log` macro on this custom behaviour
      event = EventSetup.Server.joined(:local)

      # Simulates the handler receiving the event
      assert :ok == LogHandler.handle_event(event)

      [log_server] = LogQuery.get_logs_on_server(event.server_id)
      assert_log log_server, event.server_id, event.entity_id,
        :local_login, %{}
    end
  end

  describe "log_forge_processed/1 for LogForge.Edit" do
    test "adds a revision to the target log" do
      log = LogSetup.log!()
      process =
        ProcessSetup.fake_process!(
          type: :log_forge_edit,
          tgt_log_id: log.log_id,
          data: [forger_version: 50]
        )
      event = EventSetup.Log.forge_processed(process: process)

      # Sanity check: we are editing the log we've created
      assert event.target_log_id == process.tgt_log_id
      assert event.action == :edit

      log_before = LogQuery.fetch(log.log_id)

      # Simulate handling of the event
      LogHandler.log_forge_processed(event)

      log_after = LogQuery.fetch(log.log_id)

      # `log_after` had a revision added to it.
      assert log_after.revision_id == log_before.revision_id + 1
      assert log_after.revision != log_before.revision

      # `log_after` revision is exactly the one specified at `event`/`process`
      assert log_after.revision.type == process.data.log_type
      assert_map_str log_after.revision.data,
        Map.from_struct(process.data.log_data)
      assert log_after.revision.forge_version == 50
    end
  end

  describe "log_forge_processed/1 for LogForge.Create" do
    test "creates a new log" do
      process =
        ProcessSetup.fake_process!(
          type: :log_forge_create, data: [forger_version: 50]
        )
      event = EventSetup.Log.forge_processed(process: process)

      # Sanity check: we are creating a new log
      refute event.target_log_id
      assert event.action == :create

      # Initially, the process (target) server has no logs
      assert [] == LogQuery.get_logs_on_server(process.target_id)

      # Simulate handling of the event
      LogHandler.log_forge_processed(event)

      # Now the process server has a new log
      assert [log] = LogQuery.get_logs_on_server(process.target_id)

      # And the new log has exactly the data described at `event`/`process`
      assert log.revision_id == 1
      assert log.revision.type == process.data.log_type
      assert_map_str log.revision.data, Map.from_struct(process.data.log_data)
      assert log.revision.forge_version == 50
    end
  end
end
