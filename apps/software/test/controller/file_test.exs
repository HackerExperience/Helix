defmodule HELM.Software.Controller.FileTest do
  use ExUnit.Case

  alias HELL.TestHelper.Random, as: HRand
  alias HELM.Software.Controller.FileType, as: CtrlFileType
  alias HELM.Software.Controller.Storage, as: CtrlStorage
  alias HELM.Software.Controller.File, as: CtrlFile

  setup do
    file_type_name = HRand.string()
    file_size = HRand.number(min: 1)

    file_type_payload = %{file_type: file_type_name, extension: ".test"}

    {:ok, file_type} = CtrlFileType.create(file_type_payload)
    {:ok, storage} = CtrlStorage.create()

    payload = %{
      name: "void",
      file_path: "/dev/null",
      file_type: file_type.file_type,
      file_size: file_size,
      storage_id: storage.storage_id
    }

    {:ok, payload: payload}
  end

  test "create/1", %{payload: payload} do
    assert {:ok, _} = CtrlFile.create(payload)
  end

  describe "find/1" do
    test "success", %{payload: payload} do
      assert {:ok, file} = CtrlFile.create(payload)
      assert {:ok, ^file} = CtrlFile.find(file.file_id)
    end

    test "failure" do
      assert {:error, :notfound} = CtrlFile.find(UUID.uuid4())
    end
  end

  describe "update/2" do
    test "success", %{payload: payload} do
      {:ok, update_storage} = CtrlStorage.create()

      update_payload = %{
        name: "null",
        file_path: "/dev/urandom",
        storage_id: update_storage.storage_id
      }

      assert {:ok, file} = CtrlFile.create(payload)
      assert {:ok, _} = CtrlFile.update(file.file_id, update_payload)
      assert {:ok, updated_file} = CtrlFile.find(file.file_id)

      assert updated_file.name == update_payload.name
      assert updated_file.file_path == update_payload.file_path
      assert updated_file.storage_id == update_payload.storage_id
    end

    test "failure" do
      assert {:error, :notfound} = CtrlFile.update(UUID.uuid4(), %{})
    end
  end

  test "delete/1 idempotency", %{payload: payload} do
    assert {:ok, file} = CtrlFile.create(payload)
    assert :ok = CtrlFile.delete(file.file_id)
    assert :ok = CtrlFile.delete(file.file_id)
    assert {:error, :notfound} = CtrlFile.find(file.file_id)
  end
end