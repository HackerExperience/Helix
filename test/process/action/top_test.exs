defmodule Helix.Process.Action.TOPTest do

  use Helix.Test.Case.Integration

  alias Helix.Process.Action.TOP, as: TOPAction
  alias Helix.Process.Model.TOP

  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
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
    test "performs recalque of both gateway and target (for inter-top procs)" do
      {gateway, _} = ServerSetup.server()
      {target, _} = ServerSetup.server()

      {total_resources, _} =
        ProcessSetup.TOP.Resources.resources(network_id: :net)

      {proc, _} =
        ProcessSetup.process(
          gateway_id: gateway.server_id,
          target_server_id: target.server_id,
          type: :file_download,
          l_limit: %{dlk: %{"::" => 50}},
          r_limit: %{ulk: %{"::" => 20}},
          static: %{}
        )

      assert %{
        gateway: gateway,
        target: target
      } = TOPAction.recalque(gateway.server_id, target.server_id, [])

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

      # TODO: Missing stricter checks
    end
  end
end
