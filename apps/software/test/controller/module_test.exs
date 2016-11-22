defmodule HELM.Software.Controller.ModuleTest do
  use ExUnit.Case

  alias HELL.IPv6
  alias HELL.TestHelper.Random, as: HRand
  alias HELM.Software.Repo
  alias HELM.Software.Model.FileType, as: MdlFileType
  alias HELM.Software.Model.ModuleRole, as: MdlModuleRole
  alias HELM.Software.Controller.File, as: CtrlFile
  alias HELM.Software.Controller.Module, as: CtrlModule
  alias HELM.Software.Controller.Storage, as: CtrlStorage

  @file_type HRand.string(min: 20)
  @module_role HRand.string(min: 20)

  setup_all do
    %{file_type: @file_type, extension: ".test"}
    |> MdlFileType.create_changeset()
    |> Repo.insert!()

    %{module_role: @module_role, file_type: @file_type}
    |> MdlModuleRole.create_changeset()
    |> Repo.insert!()

    :ok
  end

  setup do
    {:ok, storage} = CtrlStorage.create()

    file_payload = %{
      name: "void",
      file_path: "/dev/null",
      file_type: @file_type,
      file_size: HRand.number(min: 1),
      storage_id: storage.storage_id
    }

    {:ok, file} = CtrlFile.create(file_payload)

    payload = %{
      module_role: @module_role,
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
      assert {:ok, ^module} = CtrlModule.find(module.file_id, module.module_role)
    end

    test "failure" do
      assert {:error, :notfound} = CtrlModule.find(IPv6.generate([]), "")
    end
  end

  test "delete/2 idempotency", %{payload: payload} do
    assert {:ok, module} = CtrlModule.create(payload)

    assert :ok = CtrlModule.delete(module.file_id, module.module_role)
    assert :ok = CtrlModule.delete(module.file_id, module.module_role)

    assert {:error, :notfound} = CtrlModule.find(module.file_id, module.module_role)
  end
end