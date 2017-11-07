defmodule Helix.Process.Action.TOPTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Process.Macros

  alias Helix.Process.Action.TOP, as: TOPAction
  alias Helix.Process.Model.Process
  alias Helix.Process.Query.Process, as: ProcessQuery

  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Process.Helper, as: ProcessHelper
  alias Helix.Test.Process.Setup, as: ProcessSetup

  @internet_id NetworkHelper.internet_id()

  describe "complete/1" do
    test "completes process when it has actually reached its objective" do
      {proc, _} = ProcessSetup.fake_process()

      # Has processed everything it was supposed to; it's completed.
      proc =
        %{proc|
          processed: proc.objective,
          l_allocated: %{cpu: 1, ram: 1, ulk: %{}, dlk: %{}}
        }

      assert {:ok, events} = TOPAction.complete(proc)

      # Two events; one is ProcessCompletedEvent, the other is the corresponding
      # <Action>ProcessedEvent (e.g. FileTransferProcessedEvent).
      assert length(events) == 2
    end

    test "fails if process hasn't actually finished yet" do
      [proc] =
        ProcessSetup.TOP.fake_process(
          l_dynamic: [:ulk, :dlk, :ram, :cpu],
          l_allocated: %{cpu: 1, ram: 1, dlk: %{}, ulk: %{}}
        )

      assert {:error, reason, []} = TOPAction.complete(proc)
      assert reason == {:process, :running}
    end
  end

  describe "recalque/3" do
    test "persists processed information" do
      {gateway, _} = ServerSetup.server()

      {proc, _} =
        ProcessSetup.process(
          gateway_id: gateway.server_id,
          type: :bruteforce,
          static: %{},
          objective: %{cpu: 9999}
        )

      # At this moment, we have `proc` inserted on the Database, but it never
      # went through any allocation/recalque. Let's fetch it now.
      process = ProcessQuery.fetch(proc.process_id)

      # See? `waiting_allocation`, `l_reserved` never was touched, etc
      assert process.state == :waiting_allocation
      assert process.l_allocated == Process.Resources.initial()
      assert process.l_reserved == Process.Resources.initial()

      # Now let's run recalque on this server. We'll ignore remote for now.
      assert {:ok, [proc_recalque], _} = TOPAction.recalque(gateway.server_id)

      # The process state has been changed
      assert proc_recalque.state == :running

      # Resources were reserved
      assert proc_recalque.l_reserved.cpu > 0

      # But it hasn't processed anything yet (it's the first allocation)
      assert proc_recalque.processed == Process.Resources.initial()

      # OK, the returned value of the recalque is valid. How about whatever was
      # persisted on the DB? Let's see
      proc_db = ProcessQuery.fetch(proc.process_id)

      # At the very least, state and `l_reserved` must match
      assert proc_db.state == :running
      assert proc_db.l_reserved == proc_recalque.l_reserved

      # Still hasn't processed anything
      # refute proc_db.processed

      # Some time_left was assigned
      assert proc_db.time_left > 0

      # Let's recalque the TOP again. Theoretically, nothing should change.
      assert {:ok, [proc_recalque2], _} = TOPAction.recalque(gateway.server_id)

      # Allocation is the same...
      assert proc_recalque2.next_allocation == proc_recalque.next_allocation

      # Now this is interesting. We'll detail this verification below because
      # it *is* important (and it *does* fixes a bug).
      # See, `proc_recalque2`'s `processed` is different than `proc_recalque`.
      # As you may remember, `proc_recalque` has never processed anything, while
      # `proc_recalque2` has (even if just for a few milliseconds).
      # This is correct! HOWEVER, the `processed` information is modified after
      # the process was fetched from the DB, so the verification below does not
      # guarantee that the `processed` field has been saved correctly in the DB.
      refute proc_recalque2.processed == Process.Resources.initial()

      # Interestingly, `processed` is only updated on the DB when the current
      # process' allocation has changed. So in the scenario above, even though
      # `proc_recalque2` did process something, this information is not saved
      # on the DB. Instead, it is derived from the process' current stats.
      raw_proc = ProcessHelper.raw_get(process.process_id)

      # See? It's empty
      refute raw_proc.processed

      # In order to test this, we'll need to make the process allocation change
      # somehow. Let's cheat and reduce the server's total CPU. This should
      # reduce the process allocation, which uses 100% of the available CPU.
      ServerHelper.update_server_specs(gateway, %{cpu: 500})

      # So, let's recalque again and see if something changed
      assert {:ok, [proc_recalque3], _} = TOPAction.recalque(gateway.server_id)

      # Reserved/allocated CPU went down to 500
      refute proc_recalque3.next_allocation == proc_recalque2.next_allocation
      refute proc_recalque3.l_reserved == proc_recalque2.l_reserved
      assert_resource proc_recalque3.l_reserved.cpu, 500

      # How about the processed (on DB)?
      raw_proc = ProcessHelper.raw_get(process.process_id)

      # Yep, it's saved there
      assert raw_proc.processed["cpu"] > 0
    end

    test "performs recalque of both gateway and target (for inter-top procs)" do
      {gateway, _} = ServerSetup.server()
      {target, _} = ServerSetup.server()

      {proc, _} =
        ProcessSetup.process(
          gateway_id: gateway.server_id,
          target_id: target.server_id,
          type: :file_download,
          l_limit: %{dlk: %{"::" => 50}},
          r_limit: %{ulk: %{"::" => 20}},
          static: %{}
        )

      assert %{gateway: gateway, target: target} = TOPAction.recalque(proc)

      {:ok, [gateway_proc], _} = gateway
      {:ok, [target_proc], _} = target

      # Remember, it's the same process
      assert gateway_proc.process_id == target_proc.process_id

      # On the gateway, reserved 50 units of DLK
      assert gateway_proc.l_reserved.dlk[@internet_id] == 50
      assert gateway_proc.l_reserved.ulk[@internet_id] == 0
      assert gateway_proc.l_reserved.cpu == 0
      assert gateway_proc.l_reserved.ram == 0

      # On the target, reserved 20 units of ULK
      assert target_proc.r_reserved.ulk[@internet_id] == 20
      assert target_proc.r_reserved.dlk == %{}
      assert target_proc.r_reserved.cpu == 0
      assert target_proc.r_reserved.ram == 0

      # More tests exploring edge-cases of Inter-TOP allocation at
      # `test/features/process/*`.
    end
  end
end
