defmodule HELM.Process.Controller.ProcessTest do
  use ExUnit.Case

  alias HELM.Process.Controller.Process, as: CtrlProcess

  test "create/1" do
    assert {:ok, _} = CtrlProcess.create(%{})
  end

  describe "find/1" do
    test "success" do
      {:ok, process} = CtrlProcess.create(%{})
      assert {:ok, ^process} = CtrlProcess.find(process.process_id)
    end

    test "failure" do
      assert {:error, :notfound} = CtrlProcess.find(UUID.uuid4())
    end
  end

  test "delete/1 idempotency" do
    {:ok, process} = CtrlProcess.create(%{})
    assert :ok = CtrlProcess.delete(process.process_id)
    assert :ok = CtrlProcess.delete(process.process_id)
  end
end