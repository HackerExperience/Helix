defmodule HELM.Software.Module.ControllerTest do
  use ExUnit.Case

  alias HELL.Random, as: HRand
  alias HELM.Software.File.Controller, as: FileCtrl
  alias HELM.Software.Module.Controller, as: ModuleCtrl
  alias HELM.Software.Storage.Controller, as: StorageCtrl
  alias HELM.Software.File.Type.Controller, as: FileTypeCtrl
  alias HELM.Software.Module.Role.Controller, as: ModuleRoleCtrl

  describe "creation" do
    test "success" do
      file_type_name = HRand.random_numeric_string()
      role_name = HRand.random_numeric_string()
      file_size = HRand.random_number()
      module_version = HRand.random_number()

      {:ok, file_type} = FileTypeCtrl.create(file_type_name, ".test")
      {:ok, role} = ModuleRoleCtrl.create(role_name, file_type.file_type)
      {:ok, storage} = StorageCtrl.create()
      {:ok, file} = FileCtrl.create(storage.storage_id, "/dev/null", "void", file_type.file_type, file_size)

      assert {:ok, _} = ModuleCtrl.create(role.module_role, file.file_id, module_version)
    end
  end

  describe "search" do
    test "success" do
      file_type_name = HRand.random_numeric_string()
      role_name = HRand.random_numeric_string()
      file_size = HRand.random_number()
      module_version = HRand.random_number()

      {:ok, file_type} = FileTypeCtrl.create(file_type_name, ".test")
      {:ok, role} = ModuleRoleCtrl.create(role_name, file_type.file_type)
      {:ok, storage} = StorageCtrl.create()
      {:ok, file} = FileCtrl.create(storage.storage_id, "/dev/null", "void", file_type.file_type, file_size)
      {:ok, module} = ModuleCtrl.create(role.module_role, file.file_id, module_version)

      assert {:ok, module} = ModuleCtrl.find(role.module_role, file.file_id)
    end
  end

  describe "removal" do
    test "success" do
      file_type_name = HRand.random_numeric_string()
      role_name = HRand.random_numeric_string()
      file_size = HRand.random_number()
      module_version = HRand.random_number()

      {:ok, file_type} = FileTypeCtrl.create(file_type_name, ".test")
      {:ok, role} = ModuleRoleCtrl.create(role_name, file_type.file_type)
      {:ok, storage} = StorageCtrl.create()
      {:ok, file} = FileCtrl.create(storage.storage_id, "/dev/null", "void", file_type.file_type, file_size)
      {:ok, module} = ModuleCtrl.create(role.module_role, file.file_id, module_version)

      assert {:ok, _} = ModuleCtrl.delete(role.module_role, file.file_id)
    end
  end
end
