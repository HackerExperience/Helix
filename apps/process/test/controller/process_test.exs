defmodule Helix.Process.Controller.ProcessTest do
  use ExUnit.Case

  alias HELL.IPv6
  alias Helix.Process.Controller.Process, as: CtrlProcess

  @tag :pending
  test "create/1" do
    assert {:ok, _} = CtrlProcess.create(%{})
  end

  describe "find/1" do
    @tag :pending
    test "success" do
      {:ok, process} = CtrlProcess.create(%{})
      assert {:ok, ^process} = CtrlProcess.find(process.process_id)
    end

    @tag :pending
    test "failure" do
      assert {:error, :notfound} = CtrlProcess.find(IPv6.generate([]))
    end
  end

  @tag :pending
  test "delete/1 idempotency" do
    {:ok, process} = CtrlProcess.create(%{})
    assert :ok = CtrlProcess.delete(process.process_id)
    assert :ok = CtrlProcess.delete(process.process_id)
  end
end