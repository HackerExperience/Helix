defmodule HELM.Software.Controller.FileTypeTest do
  use ExUnit.Case

  alias HELL.Random, as: HRand
  alias HELM.Software.Controller.FileType, as: CtrlFileType

  setup do
    payload = %{
      file_type: HRand.random_numeric_string(),
      extension: ".test"
    }

    {:ok, payload: payload}
  end

  test "create/1", %{payload: payload} do
    assert {:ok, _} = CtrlFileType.create(payload)
  end

  describe "find/1" do
    test "success", %{payload: payload} do
      {:ok, file} = CtrlFileType.create(payload)
      assert {:ok, ^file} = CtrlFileType.find(file.file_type)
    end

    test "failure" do
      assert {:error, :notfound} = CtrlFileType.find("")
    end
  end

  test "delete/1 idempotency", %{payload: payload}  do
    {:ok, file} = CtrlFileType.create(payload)

    assert :ok = CtrlFileType.delete(file.file_type)
    assert :ok = CtrlFileType.delete(file.file_type)

    assert {:error, :notfound} = CtrlFileType.find(file.file_type)
  end
end