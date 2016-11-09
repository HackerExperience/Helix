defmodule HELM.Software.Controller.ModuleTest do
  use ExUnit.Case

  alias HELL.IPv6
  alias HELL.TestHelper.Random, as: HRand
  alias HELM.Software.Controller.File, as: CtrlFile
  alias HELM.Software.Controller.Module, as: CtrlModule
  alias HELM.Software.Controller.Storage, as: CtrlStorage
  alias HELM.Software.Controller.FileType, as: CtrlFileType
  alias HELM.Software.Controller.ModuleRole, as: CtrlModuleRole

  setup do
    file_type_payload = %{
      file_type: HRand.string(),
      extension: ".test"
    }

    {:ok, file_type} = CtrlFileType.create(file_type_payload)

    module_role_payload = %{
      module_role: HRand.string(),
      file_type: file_type.file_type
    }

    {:ok, storage} = CtrlStorage.create()
    {:ok, role} = CtrlModuleRole.create(module_role_payload)

    file_payload = %{
      name: "void",
      file_path: "/dev/null",
      file_type: file_type.file_type,
      file_size: HRand.number(min: 1),
      storage_id: storage.storage_id
    }

    {:ok, file} = CtrlFile.create(file_payload)

    payload = %{
      module_role: role.module_role,
      file_id: file.file_id,
      module_version: HRand.number(min: 1)
    }

    {:ok, payload: payload}
  end

  test "create/1", %{payload: payload} do
    assert {:ok, _} = CtrlModule.create(payload)
  end

  describe "find/2" do
    test "success", %{payload: payload} do
      assert {:ok, module} = CtrlModule.create(payload)
      assert {:ok, ^module} = CtrlModule.find(module.module_role, module.file_id)
    end

    test "failure" do
      assert {:error, :notfound} = CtrlModule.find("", IPv6.generate([]))
    end
  end

  test "delete/2 idempotency", %{payload: payload} do
    assert {:ok, module} = CtrlModule.create(payload)

    assert :ok = CtrlModule.delete(module.module_role, module.file_id)
    assert :ok = CtrlModule.delete(module.module_role, module.file_id)

    assert {:error, :notfound} = CtrlModule.find(module.module_role, module.file_id)
  end
end