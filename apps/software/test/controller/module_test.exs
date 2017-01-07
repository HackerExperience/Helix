defmodule Helix.Software.Controller.ModuleTest do

  use ExUnit.Case, async: true

  alias HELL.PK
  alias HELL.TestHelper.Random, as: HRand
  alias Helix.Software.Repo
  alias Helix.Software.Model.FileType
  alias Helix.Software.Model.ModuleRole
  alias Helix.Software.Controller.File, as: CtrlFile
  alias Helix.Software.Controller.Module, as: CtrlModule
  alias Helix.Software.Controller.Storage, as: CtrlStorage

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
      assert {:error, :notfound} == CtrlModule.find(PK.generate([]), PK.generate([]))
    end
  end

  describe "update/3" do
    test "update module version", %{payload: payload} do
      assert {:ok, module} = CtrlModule.create(payload)

      payload2 = %{module_version: 2}
      assert {:ok, module} = CtrlModule.update(module.file_id, module.module_role_id, payload2)
      assert payload2.module_version == module.module_version
    end

    test "module not found" do
      assert {:error, :notfound} == CtrlModule.update(PK.generate([]), PK.generate([]), %{})
    end
  end

  test "delete/2 idempotency", %{payload: payload} do
    {:ok, module} = CtrlModule.create(payload)

    :ok = CtrlModule.delete(module.file_id, module.module_role_id)
    :ok = CtrlModule.delete(module.file_id, module.module_role_id)

    assert {:error, :notfound} == CtrlModule.find(module.file_id, module.module_role_id)
  end
end