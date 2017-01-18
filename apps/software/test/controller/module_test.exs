defmodule Helix.Software.Controller.ModuleTest do

  use ExUnit.Case, async: true

  alias HELL.PK
  alias HELL.TestHelper.Random, as: HRand
  alias Helix.Software.Repo
  alias Helix.Software.Model.FileType
  alias Helix.Software.Model.ModuleRole
  alias Helix.Software.Controller.File, as: FileController
  alias Helix.Software.Controller.Module, as: ModuleController
  alias Helix.Software.Controller.Storage, as: StorageController

  setup do
    file_type = FileType |> Repo.all() |> Enum.random() |> Map.fetch!(:file_type)
    role = ModuleRole |> Repo.all() |> Enum.random() |> Map.fetch!(:module_role_id)

    {:ok, storage} = StorageController.create()

    file_payload = %{
      name: "void",
      file_path: "/dev/null",
      file_type: file_type,
      file_size: HRand.number(min: 1),
      storage_id: storage.storage_id
    }

    {:ok, file} = FileController.create(file_payload)

    payload = %{
      module_role_id: role,
      file_id: file.file_id,
      module_version: HRand.number(min: 1)
    }

    {:ok, payload: payload}
  end

  test "create/1", %{payload: payload} do
    assert {:ok, _} = ModuleController.create(payload)
  end

  describe "find/2" do
    test "success", %{payload: payload} do
      assert {:ok, module} = ModuleController.create(payload)
      assert {:ok, ^module} = ModuleController.find(module.file_id, module.module_role_id)
    end

    test "failure" do
      assert {:error, :notfound} == ModuleController.find(PK.generate([]), PK.generate([]))
    end
  end

  describe "update/3" do
    test "update module version", %{payload: payload} do
      assert {:ok, module} = ModuleController.create(payload)

      payload2 = %{module_version: 2}
      assert {:ok, module} = ModuleController.update(module.file_id, module.module_role_id, payload2)
      assert payload2.module_version == module.module_version
    end

    test "module not found" do
      assert {:error, :notfound} == ModuleController.update(PK.generate([]), PK.generate([]), %{})
    end
  end

  test "delete/2 idempotency", %{payload: payload} do
    {:ok, module} = ModuleController.create(payload)

    :ok = ModuleController.delete(module.file_id, module.module_role_id)
    :ok = ModuleController.delete(module.file_id, module.module_role_id)

    assert {:error, :notfound} == ModuleController.find(module.file_id, module.module_role_id)
  end
end