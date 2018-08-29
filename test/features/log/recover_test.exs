defmodule Helix.Test.Features.Log.Recover do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest
  import Helix.Test.Channel.Macros
  import Helix.Test.Macros

  alias Helix.Log.Query.Log, as: LogQuery
  alias Helix.Process.Model.Process
  alias Helix.Process.Query.Process, as: ProcessQuery

  alias Helix.Test.Account.Helper, as: AccountHelper
  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Channel.Request.Helper, as: RequestHelper
  alias Helix.Test.Log.Setup, as: LogSetup
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  @internet_id NetworkHelper.internet_id()

  @moduletag :feature

  describe "log recover" do
    test "LogRecover.Global life cycle (local, natural)" do
      {socket, %{entity: entity, server: gateway}} =
        ChannelSetup.create_socket()

      # Connect to gateway channel
      {socket, _} =
        ChannelSetup.join_server(
          gateway_id: gateway.server_id, own_server: true, socket: socket
        )

      # Connect to account channel, so we can receive notifications
      account_id = AccountHelper.cast_from_entity(entity.entity_id)
      ChannelSetup.join_account(socket: socket, account_id: account_id)

      # Logs that will be worked on (one of them is recoverable)
      LogSetup.log!(server_id: gateway.server_id)
      log = LogSetup.log!(server_id: gateway.server_id, revisions: 2)

      # Prepare request params
      request_id = RequestHelper.id()

      params =
        %{
          "method" => "global",
          "request_id" => request_id
        }

      # We'll attempt to recover a log at localhost. This should fail because we
      # do not have a LogRecover!
      ref = push socket, "log.recover", params
      assert_reply ref, :error, response, timeout(:fast)

      assert response.data.message == "recover_not_found"
      assert response.meta.request_id == request_id

      # Let's create the recover and try again...
      recover = SoftwareSetup.log_recover!(server_id: gateway.server_id)

      # It worked!
      ref = push socket, "log.recover", params
      assert_reply ref, :ok, _, timeout(:slow)

      [process_created_event] = wait_events [:process_created]

      assert process_created_event.data.type == "log_recover_global"
      assert process_created_event.meta.request_id == request_id

      process =
        process_created_event.data.process_id
        |> Process.ID.cast!()
        |> ProcessQuery.fetch()

      # Make sure the process was created correctly
      assert process.type == :log_recover_global
      assert process.data.recover_version == recover.modules.log_recover.version
      assert process.tgt_log_id == log.log_id

      assert process.gateway_id == gateway.server_id
      assert process.target_id == gateway.server_id
      assert process.source_entity_id == entity.entity_id
      assert process.src_file_id == recover.file_id

      # local process; no connection info
      refute process.network_id
      refute process.src_connection_id
      refute process.bounce_id

      # Simulate completion of the software
      TOPHelper.force_completion(process)

      [log_recovered_event, notification_added_event] =
        wait_events [:log_recovered, :notification_added]

      [original_revision, _fake_revision] = LogQuery.fetch_revisions(log)

      # Local server receives information about the newly recovered log
      assert log_recovered_event.data.type == to_string(original_revision.type)
      assert_map_str log_recovered_event.data.data, original_revision.data

      # The recently recovered log has changed its last revision
      new_log = LogQuery.fetch(log.log_id)

      assert new_log.revision_id == 1
      assert new_log.server_id == gateway.server_id
      assert new_log.revision.type == original_revision.type
      assert_map_str new_log.revision.data, original_revision.data

      # Client received the log notification
      assert notification_added_event.data.class == :server
      assert notification_added_event.data.code == :log_recovered
      assert notification_added_event.data.data.log_id == to_string(log.log_id)

      # LogRecoverProcess is recursive, so it should still be working.
      new_process = ProcessQuery.fetch(process.process_id)

      # It's not working on any log, as there aren't any recoverable logs now
      refute new_process.tgt_log_id

      TOPHelper.top_stop(gateway)
    end

    test "LogRecover.Custom life cycle (local, artificial)" do
      {socket, %{entity: entity, server: gateway}} =
        ChannelSetup.create_socket()

      # Connect to gateway channel
      {socket, _} =
        ChannelSetup.join_server(
          gateway_id: gateway.server_id, own_server: true, socket: socket
        )

      # Connect to account channel, so we can receive notifications
      account_id = AccountHelper.cast_from_entity(entity.entity_id)
      ChannelSetup.join_account(socket: socket, account_id: account_id)

      # Log that will be worked on
      log = LogSetup.log!(server_id: gateway.server_id, forge_version: 50)

      # Create LogRecover software
      recover = SoftwareSetup.log_recover!(server_id: gateway.server_id)

      # Prepare request params
      request_id = RequestHelper.id()

      params =
        %{
          "method" => "custom",
          "log_id" => to_string(log.log_id),
          "request_id" => request_id
        }

      # It worked!
      ref = push socket, "log.recover", params
      assert_reply ref, :ok, _, timeout(:slow)

      [process_created_event] = wait_events [:process_created]

      assert process_created_event.data.type == "log_recover_custom"
      assert process_created_event.meta.request_id == request_id

      process =
        process_created_event.data.process_id
        |> Process.ID.cast!()
        |> ProcessQuery.fetch()

      # Make sure the process was created correctly
      assert process.type == :log_recover_custom
      assert process.data.recover_version == recover.modules.log_recover.version
      assert process.tgt_log_id == log.log_id

      assert process.gateway_id == gateway.server_id
      assert process.target_id == gateway.server_id
      assert process.source_entity_id == entity.entity_id
      assert process.src_file_id == recover.file_id

      # local process; no connection info
      refute process.network_id
      refute process.src_connection_id
      refute process.bounce_id

      # Simulate completion of the software
      TOPHelper.force_completion(process)

      [log_destroyed_event, notification_added_event] =
        wait_events [:log_destroyed, :notification_added]

      # Local server receives information about the destroyed log
      assert log_destroyed_event.data.log_id == to_string(log.log_id)

      # Destroyed log no longer exists
      refute LogQuery.fetch(log.log_id)

      # Client received the log notification
      assert notification_added_event.data.class == :server
      assert notification_added_event.data.code == :log_destroyed
      assert notification_added_event.data.data.log_id == to_string(log.log_id)

      # LogRecoverProcess is recursive, so it should still be working.
      new_process = ProcessQuery.fetch(process.process_id)

      # It's not working on any log, as there aren't any recoverable logs now
      refute new_process.tgt_log_id

      TOPHelper.top_stop(gateway)
    end

    test "LogRecover.Custom life cycle (remote, natural)" do
      {socket, %{entity: entity, server: gateway}} =
        ChannelSetup.create_socket()

      # Connect to gateway channel
      {socket, %{gateway: gateway, destination: destination}} =
        ChannelSetup.join_server(gateway_id: gateway.server_id, socket: socket)

      # Connect to account channel, so we can receive notifications
      account_id = AccountHelper.cast_from_entity(entity.entity_id)
      ChannelSetup.join_account(socket: socket, account_id: account_id)

      # Relevant logs (two of them are recoverable)
      LogSetup.log!(server_id: destination.server_id, revisions: 2)
      log = LogSetup.log!(server_id: destination.server_id, revisions: 2)

      # LogRecover that will be used
      recover = SoftwareSetup.log_recover!(server_id: gateway.server_id)

      # Prepare request params
      request_id = RequestHelper.id()

      params =
        %{
          "method" => "custom",
          "log_id" => to_string(log.log_id),
          "request_id" => request_id
        }

      ref = push socket, "log.recover", params
      assert_reply ref, :ok, _, timeout(:slow)

      [process_created_event] = wait_events [:process_created]

      assert process_created_event.data.type == "log_recover_custom"
      assert process_created_event.meta.request_id == request_id

      process =
        process_created_event.data.process_id
        |> Process.ID.cast!()
        |> ProcessQuery.fetch()

      # Make sure the process was created correctly
      assert process.type == :log_recover_custom
      assert process.data.recover_version == recover.modules.log_recover.version
      assert process.tgt_log_id == log.log_id

      assert process.gateway_id == gateway.server_id
      assert process.target_id == destination.server_id
      assert process.source_entity_id == entity.entity_id
      assert process.src_file_id == recover.file_id

      # remote process; has connection info
      assert process.network_id == @internet_id
      assert process.src_connection_id == socket.assigns.ssh.connection_id

      # Simulate completion of the software
      TOPHelper.force_completion(process)

      [log_recovered_event, notification_added_event] =
        wait_events [:log_recovered, :notification_added]

      [original_revision, _fake_revision] = LogQuery.fetch_revisions(log)

      # Local server receives information about the newly recovered log
      assert log_recovered_event.data.type == to_string(original_revision.type)
      assert_map_str log_recovered_event.data.data, original_revision.data

      # The recently recovered log has changed its last revision
      new_log = LogQuery.fetch(log.log_id)

      assert new_log.revision_id == 1
      assert new_log.server_id == destination.server_id
      assert new_log.revision.type == original_revision.type
      assert_map_str new_log.revision.data, original_revision.data

      # Client received the log notification
      assert notification_added_event.data.class == :server
      assert notification_added_event.data.code == :log_recovered
      assert notification_added_event.data.data.log_id == to_string(log.log_id)

      # LogRecoverProcess is recursive, so it should still be working.
      new_process = ProcessQuery.fetch(process.process_id)

      # It's working on `log`, since it's a Custom process...
      assert new_process.tgt_log_id == log.log_id

      # But it will "never" complete, as this is the original revision
      assert new_process.time_left > 999_999_999

      TOPHelper.top_stop(gateway)
    end
  end
end
