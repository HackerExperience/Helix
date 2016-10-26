defmodule HELM.Software.Controller.ModuleRolesTest do
  use ExUnit.Case

  alias HELL.Random, as: HRand
  alias HELM.Software.Controller.FileTypes, as: CtrlFileTypes
  alias HELM.Software.Controller.ModuleRoles, as: CtrlModuleRoles

  describe "creation" do
    test "success" do
      file_type = HRand.random_numeric_string()
      role_name = HRand.random_numeric_string()
      {:ok, ftype} = CtrlFileTypes.create(file_type, ".test")
      assert {:ok, _} = CtrlModuleRoles.create(role_name, ftype.file_type)
    end
  end

  describe "search" do
    test "success" do
      file_type = HRand.random_numeric_string()
      role_name = HRand.random_numeric_string()
      {:ok, ftype} = CtrlFileTypes.create(file_type, ".test")
      {:ok, role} = CtrlModuleRoles.create(role_name, ftype.file_type)
      assert {:ok, ^role} = CtrlModuleRoles.find(role.module_role, role.file_type)
    end
  end

  describe "removal" do
    test "success" do
      file_type = HRand.random_numeric_string()
      role_name = HRand.random_numeric_string()
      {:ok, ftype} = CtrlFileTypes.create(file_type, ".test")
      {:ok, role} = CtrlModuleRoles.create(role_name, ftype.file_type)
      assert {:ok, _} = CtrlModuleRoles.delete(role.module_role, role.file_type)
    end
  end
end