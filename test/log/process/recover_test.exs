defmodule Helix.Log.Process.RecoverTest do

  use Helix.Test.Case.Integration

  alias Helix.Process.Model.Processable
  alias Helix.Process.Query.Process, as: ProcessQuery
  alias Helix.Log.Process.Recover, as: LogRecoverProcess
  alias Helix.Log.Query.Log, as: LogQuery

  alias Helix.Test.Event.Helper, as: EventHelper
  alias Helix.Test.Event.Setup, as: EventSetup
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Software.Setup, as: SoftwareSetup
  alias Helix.Test.Log.Helper, as: LogHelper
  alias Helix.Test.Log.Setup, as: LogSetup

  @relay nil

  describe "LogRecoverProcess.find_next_target/1" do
    test "returns `nil` when no logs are recoverable" do
      server_id = ServerHelper.id()

      # None logs on the server
      refute LogRecoverProcess.find_next_target(server_id)

      # Add a log, not recoverable
      LogSetup.log!(server_id: server_id)

      refute LogRecoverProcess.find_next_target(server_id)
    end

    test "selects a log when recoverable logs exist" do
      server_id = ServerHelper.id()

      # Not recoverable
      LogSetup.log!(server_id: server_id)

      # Recoverable
      log = LogSetup.log!(server_id: server_id, forge_version: 50)

      assert log.log_id == LogRecoverProcess.find_next_target(server_id).log_id

      # Another server...
      server_id2 = ServerHelper.id()

      # Recoverable
      log = LogSetup.log!(server_id: server_id2, revisions: 2)

      assert log.log_id == LogRecoverProcess.find_next_target(server_id2).log_id
    end
  end

  describe "Process.Executable" do
    test "starts the LogRecoverProcess (global) when everything is OK" do
      {gateway, %{entity: entity}} = ServerSetup.server()

      recover = SoftwareSetup.log_recover!(server_id: gateway.server_id)
      _log1 = LogSetup.log!(server_id: gateway.server_id)

      params = %{}

      meta =
        %{
          recover: recover,
          method: :global,
          log: nil,
          ssh: nil,
          network_id: nil,
          entity_id: entity.entity_id
        }

      # First we'll start the process on a server without recoverable logs
      assert {:ok, process} =
        LogRecoverProcess.execute(gateway, gateway, params, meta, @relay)

      # No log was selected; runs forever
      refute process.tgt_log_id
      assert process.objective.cpu == 999_999_999_999

      assert process.type == :log_recover_global
      assert process.data.recover_version == recover.modules.log_recover.version

      # This log is recoverable
      log2 = LogSetup.log!(server_id: gateway.server_id, revisions: 2)

      # Now we'll restart the process. `log2` should be automatically selected
      assert {:ok, process} =
        LogRecoverProcess.execute(gateway, gateway, params, meta, @relay)

      assert process.tgt_log_id == log2.log_id

      TOPHelper.top_stop(gateway)
    end

    test "starts the LogRecoverProcess (custom) when everything is OK" do
      {gateway, %{entity: entity}} = ServerSetup.server()

      recover = SoftwareSetup.log_recover!(server_id: gateway.server_id)

      # This is the log we'll attempt to recover
      log = LogSetup.log!(server_id: gateway.server_id)

      params = %{}

      meta =
        %{
          recover: recover,
          method: :custom,
          log: log,
          ssh: nil,
          network_id: nil,
          entity_id: entity.entity_id
        }

      assert {:ok, process} =
        LogRecoverProcess.execute(gateway, gateway, params, meta, @relay)

      assert process.type == :log_recover_custom
      assert process.tgt_log_id == log.log_id

      # This log is unrecoverable (already original revision), so process should
      # run "forever"
      assert process.objective.cpu == 999_999_999_999
      assert process.data.recover_version == recover.modules.log_recover.version

      TOPHelper.top_stop(gateway)
    end
  end

  describe "Process.Processable" do
    test "on_retarget/2 (global)" do
      {gateway, %{entity: entity}} = ServerSetup.server()

      recover = SoftwareSetup.log_recover!(server_id: gateway.server_id)

      # The server has two logs that are recoverable. Note that once one of them
      # gets recovered, necessarily the other one must be selected.
      LogSetup.log!(server_id: gateway.server_id, revisions: 2)
      LogSetup.log!(server_id: gateway.server_id, revisions: 2)

      params = %{}

      meta =
        %{
          recover: recover,
          method: :global,
          log: nil,
          ssh: nil,
          network_id: nil,
          entity_id: entity.entity_id
        }

      assert {:ok, process} =
        LogRecoverProcess.execute(gateway, gateway, params, meta, @relay)

      # Simulate completion
      assert {:noop, event} = Processable.complete(process.data, process)

      # Let LogHandler handle the `LogRecoverProcessedEvent`
      EventHelper.emit(event)

      assert {{:retarget, changes}, _} =
        Processable.retarget(process.data, process)

      # `retarget` selected a different log
      refute changes.tgt_log_id == process.tgt_log_id

      # And the objective to this new log isn't infinity, as it is recoverable
      refute changes.objective.cpu == 999_999_999_999

      TOPHelper.top_stop(gateway)
    end

    test "on_retarget/2 (custom)" do
      {gateway, %{entity: entity}} = ServerSetup.server()

      recover = SoftwareSetup.log_recover!(server_id: gateway.server_id)

      # This is the log we'll attempt to recover
      log = LogSetup.log!(server_id: gateway.server_id, revisions: 2)

      # This is another log that is recoverable but should be ignored by the
      # process
      LogSetup.log!(server_id: gateway.server_id, revisions: 2)

      params = %{}

      meta =
        %{
          recover: recover,
          method: :custom,
          log: log,
          ssh: nil,
          network_id: nil,
          entity_id: entity.entity_id
        }

      assert {:ok, process} =
        LogRecoverProcess.execute(gateway, gateway, params, meta, @relay)

      # Simulate completion
      assert {:noop, event} = Processable.complete(process.data, process)

      # Let LogHandler handle the `LogRecoverProcessedEvent`
      EventHelper.emit(event)

      assert {{:retarget, changes}, _} =
        Processable.retarget(process.data, process)

      # Infinity CPU objective because we've recovered the last additional
      # revision of `log`. Now it is currently at the original revision.
      assert changes.objective.cpu == 999_999_999_999
      assert changes.tgt_log_id == log.log_id

      TOPHelper.top_stop(gateway)
    end

    test "on_target_log: retargets either process when log is recovered" do
      {{:ok, process1}, %{gateway: gateway, entity_id: entity_id}} =
        LogSetup.recover_flow(method: :global, local?: true)

      # TODO: How to ensure it was retargeted?
    end

    test "on_target_log: retargets `global` process when log is destroyed" do
      # `process` is recovering `log` at `gateway`
      {{:ok, process1}, %{gateway: gateway, entity_id: entity_id}} =
        LogSetup.recover_flow(method: :global, local?: true)

      # Refetch the process so it contains allocation data
      process1 = ProcessQuery.fetch(process1.process_id)

      # This is the `log` that the process is currently targeting
      log = LogQuery.fetch(process1.tgt_log_id)

      # Now we'll gladly destroy it with LogDestroyedEvent
      # (And *actually* destroy the Log. Needed for test sequence below)
      LogHelper.delete(log)

      log
      |> EventSetup.Log.destroyed(entity_id)
      |> EventHelper.emit()

      # Process still exists
      process2 = ProcessQuery.fetch(process1.process_id)

      # The new process exists but isn't working on any log, because there was
      # only one recoverable log on `gateway` and it was destroyed. Retargeted.
      refute process2.tgt_log_id

      TOPHelper.top_stop(gateway)
    end

    test "on_target_log: deletes `custom` process when log is destroyed" do
      # `process` is recovering `log` at `gateway`
      {{:ok, process}, %{gateway: gateway, logs: [log], entity_id: entity_id}} =
        LogSetup.recover_flow(method: :custom, local?: true)

      # Now we'll gladly destroy it with LogDestroyedEvent
      log
      |> EventSetup.Log.destroyed(entity_id)
      |> EventHelper.emit()

      # Process no longer exists
      refute ProcessQuery.fetch(process.process_id)

      TOPHelper.top_stop(gateway)
    end
  end
end
