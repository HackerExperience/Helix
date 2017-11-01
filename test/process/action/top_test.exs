defmodule Helix.Process.Action.TOPTest do

  use Helix.Test.Case.Integration

  alias Helix.Process.Action.TOP, as: TOPAction
  alias Helix.Process.Model.TOP

  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Process.Setup, as: ProcessSetup

  describe "complete/1" do
    test "completes process when it has actually reached its objective" do
      {proc, _} = ProcessSetup.fake_process()

      # Has processed everything it was supposed to; it's completed.
      proc =
        %{proc|
          processed: proc.objective,
          allocated: %{cpu: 1, ram: 1, ulk: %{}, dlk: %{}}
         }

      assert {:ok, events} = TOPAction.complete(proc)

      # Two events; one is ProcessCompletedEvent, the other is the corresponding
      # <Action>ProcessedEvent (e.g. FileTransferProcessedEvent).
      assert length(events) == 2
    end

    test "fails if process hasn't actually finished yet" do
      [proc] =
        ProcessSetup.TOP.fake_process(
          dynamic: [:ulk, :dlk, :ram, :cpu],
          allocated: %{cpu: 1, ram: 1, dlk: %{}, ulk: %{}}
        )

      assert {:error, reason, []} = TOPAction.complete(proc)
      assert reason == {:process, :running}
    end
  end
end
