defmodule Helix.Process.Event.Handler.ProcessTest do

  use Helix.Test.Case.Integration

  alias Helix.Log.Query.Log, as: LogQuery
  alias Helix.Process.Query.Process, as: ProcessQuery

  alias Helix.Test.Event.Helper, as: EventHelper
  alias Helix.Test.Event.Setup, as: EventSetup
  alias Helix.Test.Log.Setup, as: LogSetup
  alias Helix.Test.Process.TOPHelper

  describe "ProcessSignaledEvent" do
    test ":retarget - modifies process target, objectives" do
      # `process1` is recovering `log` at `gateway`
      {{:ok, process1}, %{gateway: gateway}} =
        LogSetup.recover_flow(method: :global, local?: true)

      # Wait 100ms to give some working time for the process
      :timer.sleep(100)

      # Refetch the process so it contains allocation data
      process1 = ProcessQuery.fetch(process1.process_id)

      # This is the `log` that the process is currently targeting
      LogQuery.fetch(process1.tgt_log_id)

      # An empty map indicates nothing will actually change on the process, but
      # the underlying `processed` and `last_checkpoint_time` should be reset.
      changes = %{}

      # Force retarget
      process1
      |> EventSetup.Process.signaled(:SIGRETARGET, {:retarget, changes}, %{})
      |> EventHelper.emit()

      process2 = ProcessQuery.fetch(process1.process_id)

      # Retarget changed the process' `last_checkpoint_time`
      refute process1.last_checkpoint_time == process2.last_checkpoint_time

      # All else being equal, `process2` takes longer to complete
      assert process2.time_left > process1.time_left
      assert process2.percentage < process1.percentage

      TOPHelper.top_stop(gateway)
    end
  end
end
