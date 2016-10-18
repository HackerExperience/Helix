defmodule HELM.Software.Module.Role.ControllerTest do
  use ExUnit.Case

  alias HELL.Random, as: HRand
  alias HELM.Software.File.Type.Controller, as: FileTypeCtrl
  alias HELM.Software.Module.Role.Controller, as: ModuleRoleCtrl

  describe "creation" do
    test "success" do
      file_type = HRand.random_numeric_string()
      role_name = HRand.random_numeric_string()
      {:ok, ftype} = FileTypeCtrl.create(file_type, ".test")
      assert {:ok, _} = ModuleRoleCtrl.create(role_name, ftype.file_type)
    end
  end

  describe "search" do
    test "success" do
      file_type = HRand.random_numeric_string()
      role_name = HRand.random_numeric_string()
      {:ok, ftype} = FileTypeCtrl.create(file_type, ".test")
      {:ok, role} = ModuleRoleCtrl.create(role_name, ftype.file_type)
      assert {:ok, role} = ModuleRoleCtrl.find(role.module_role, role.file_type)
    end
  end

  describe "removal" do
    test "success" do
      file_type = HRand.random_numeric_string()
      role_name = HRand.random_numeric_string()
      {:ok, ftype} = FileTypeCtrl.create(file_type, ".test")
      {:ok, role} = ModuleRoleCtrl.create(role_name, ftype.file_type)
      assert {:ok, _} = ModuleRoleCtrl.delete(role.module_role, role.file_type)
    end
  end
end
