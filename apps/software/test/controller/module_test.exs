defmodule HELM.Software.Controller.ModuleTest do
  use ExUnit.Case

  alias HELL.Random, as: HRand
  alias HELM.Software.Controller.File, as: CtrlFile
  alias HELM.Software.Controller.Module, as: CtrlModules
  alias HELM.Software.Controller.Storage, as: CtrlStorage
  alias HELM.Software.Controller.FileType, as: CtrlFileType
  alias HELM.Software.Controller.ModuleRole, as: CtrlModuleRole

  describe "creation" do
    test "success" do
      file_type_name = HRand.random_numeric_string()
      role_name = HRand.random_numeric_string()
      file_size = HRand.random_number()
      module_version = HRand.random_number()

      {:ok, file_type} = CtrlFileType.create(file_type_name, ".test")
      {:ok, role} = CtrlModuleRole.create(role_name, file_type.file_type)
      {:ok, storage} = CtrlStorage.create()
      {:ok, file} = CtrlFile.create(storage.storage_id, "/dev/null", "void", file_type.file_type, file_size)

      assert {:ok, _} = CtrlModules.create(role.module_role, file.file_id, module_version)
    end
  end

  describe "search" do
    test "success" do
      file_type_name = HRand.random_numeric_string()
      role_name = HRand.random_numeric_string()
      file_size = HRand.random_number()
      module_version = HRand.random_number()

      {:ok, file_type} = CtrlFileType.create(file_type_name, ".test")
      {:ok, role} = CtrlModuleRole.create(role_name, file_type.file_type)
      {:ok, storage} = CtrlStorage.create()
      {:ok, file} = CtrlFile.create(storage.storage_id, "/dev/null", "void", file_type.file_type, file_size)
      {:ok, module} = CtrlModules.create(role.module_role, file.file_id, module_version)

      assert {:ok, ^module} = CtrlModules.find(role.module_role, file.file_id)
    end
  end

  describe "removal" do
    test "success" do
      file_type_name = HRand.random_numeric_string()
      role_name = HRand.random_numeric_string()
      file_size = HRand.random_number()
      module_version = HRand.random_number()

      {:ok, file_type} = CtrlFileType.create(file_type_name, ".test")
      {:ok, role} = CtrlModuleRole.create(role_name, file_type.file_type)
      {:ok, storage} = CtrlStorage.create()
      {:ok, file} = CtrlFile.create(storage.storage_id, "/dev/null", "void", file_type.file_type, file_size)
      {:ok, _} = CtrlModules.create(role.module_role, file.file_id, module_version)

      assert {:ok, _} = CtrlModules.delete(role.module_role, file.file_id)
    end
  end
end