defmodule HELM.Software.Controller.ModuleTest do

  use ExUnit.Case, async: true

  alias HELL.IPv6
  alias HELL.TestHelper.Random, as: HRand
  alias HELM.Software.Repo
  alias HELM.Software.Model.FileType
  alias HELM.Software.Model.ModuleRole
  alias HELM.Software.Controller.File, as: CtrlFile
  alias HELM.Software.Controller.Module, as: CtrlModule
  alias HELM.Software.Controller.Storage, as: CtrlStorage

  setup do
    file_type = FileType |> Repo.all() |> Enum.random() |> Map.fetch!(:file_type)
    role = ModuleRole |> Repo.all() |> Enum.random() |> Map.fetch!(:module_role_id)

    {:ok, storage} = CtrlStorage.create()

    file_payload = %{
      name: "void",
      file_path: "/dev/null",
      file_type: file_type,
      file_size: HRand.number(min: 1),
      storage_id: storage.storage_id
    }

    {:ok, file} = CtrlFile.create(file_payload)

    payload = %{
      module_role_id: role,
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
      assert {:ok, ^module} = CtrlModule.find(module.file_id, module.module_role_id)
    end

    test "failure" do
      assert {:error, :notfound} = CtrlModule.find(IPv6.generate([]), IPv6.generate([]))
    end
  end

  describe "update/3" do
    test "update module version", %{payload: payload} do
      assert {:ok, module} = CtrlModule.create(payload)

      payload2 = %{module_version: 2}
      assert {:ok, module} = CtrlModule.update(module.file_id, module.module_role, payload2)
      assert module.module_version == payload2.module_version
    end

    test "module not found" do
      assert {:error, :notfound} = CtrlModule.update(IPv6.generate([]), HRand.string(min: 20), %{})
    end
  end

  test "delete/2 idempotency", %{payload: payload} do
    assert {:ok, module} = CtrlModule.create(payload)

    assert :ok = CtrlModule.delete(module.file_id, module.module_role_id)
    assert :ok = CtrlModule.delete(module.file_id, module.module_role_id)

    assert {:error, :notfound} = CtrlModule.find(module.file_id, module.module_role_id)
  end
end