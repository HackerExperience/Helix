defmodule HELM.Software.Controller.StorageTest do
  use ExUnit.Case
  alias HELM.Software.Controller.Storage, as: CtrlStorage

  test "create/1" do
    assert {:ok, _} = CtrlStorage.create()
  end

  describe "find/1" do
    test "success" do
      {:ok, storage} = CtrlStorage.create()
      assert {:ok, ^storage} = CtrlStorage.find(storage.storage_id)
    end

    test "failure" do
      assert {:error, :notfound} = CtrlStorage.find("")
    end
  end

  test "delete/2 idempotency" do
    {:ok, storage} = CtrlStorage.create()

    assert :ok = CtrlStorage.delete(storage.storage_id)
    assert :ok = CtrlStorage.delete(storage.storage_id)

    assert {:error, :notfound} = CtrlStorage.find(storage.storage_id)
  end
end