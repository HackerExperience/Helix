defmodule HELM.Software.Controller.ModuleRoleTest do
  use ExUnit.Case

  alias HELL.Random, as: HRand
  alias HELM.Software.Controller.FileType, as: CtrlFileType
  alias HELM.Software.Controller.ModuleRole, as: CtrlModuleRole

  describe "creation" do
    test "success" do
      file_type = HRand.random_numeric_string()
      role_name = HRand.random_numeric_string()
      {:ok, ftype} = CtrlFileType.create(file_type, ".test")
      assert {:ok, _} = CtrlModuleRole.create(role_name, ftype.file_type)
    end
  end

  describe "search" do
    test "success" do
      file_type = HRand.random_numeric_string()
      role_name = HRand.random_numeric_string()
      {:ok, ftype} = CtrlFileType.create(file_type, ".test")
      {:ok, role} = CtrlModuleRole.create(role_name, ftype.file_type)
      assert {:ok, ^role} = CtrlModuleRole.find(role.module_role, role.file_type)
    end
  end

  describe "removal" do
    test "success" do
      file_type = HRand.random_numeric_string()
      role_name = HRand.random_numeric_string()
      {:ok, ftype} = CtrlFileType.create(file_type, ".test")
      {:ok, role} = CtrlModuleRole.create(role_name, ftype.file_type)
      assert {:ok, _} = CtrlModuleRole.delete(role.module_role, role.file_type)
    end
  end
end