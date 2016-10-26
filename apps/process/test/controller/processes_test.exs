defmodule HELM.Controller.ProcessesTest do
  use ExUnit.Case

  alias HELM.Process.Controller.Processes, as: CtrlProcesses

  test "create/1" do
    assert {:ok, _} = CtrlProcesses.create(%{})
  end

  describe "find/1" do
    test "success" do
      {:ok, process} = CtrlProcesses.create(%{})
      assert {:ok, ^process} = CtrlProcesses.find(process.process_id)
    end

    test "failure" do
      assert {:error, :notfound} = CtrlProcesses.find("")
    end
  end

  test "delete/1 idempotency" do
    {:ok, process} = CtrlProcesses.create(%{})
    assert :ok = CtrlProcesses.delete(process.process_id)
    assert :ok = CtrlProcesses.delete(process.process_id)
  end
end