defmodule Helix.Process.Controller.ProcessTest do
  use ExUnit.Case

  alias HELL.PK
  alias Helix.Process.Controller.Process, as: ProcessController

  @tag :pending
  test "create/1" do
    assert {:ok, _} = ProcessController.create(%{})
  end

  describe "find/1" do
    @tag :pending
    test "success" do
      {:ok, process} = ProcessController.create(%{})
      assert {:ok, ^process} = ProcessController.find(process.process_id)
    end

    @tag :pending
    test "failure" do
      assert {:error, :notfound} = ProcessController.find(PK.generate([]))
    end
  end

  @tag :pending
  test "delete/1 idempotency" do
    {:ok, process} = ProcessController.create(%{})
    assert :ok = ProcessController.delete(process.process_id)
    assert :ok = ProcessController.delete(process.process_id)
  end
end