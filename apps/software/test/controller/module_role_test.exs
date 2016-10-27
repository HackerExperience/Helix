defmodule HELM.Software.Controller.ModuleRoleTest do
  use ExUnit.Case

  alias HELL.Random, as: HRand
  alias HELM.Software.Controller.FileType, as: CtrlFileType
  alias HELM.Software.Controller.ModuleRole, as: CtrlModuleRole

  setup do
    file_type_payload = %{
      file_type: HRand.random_numeric_string(),
      extension: ".test"
    }

    {:ok, file_type} = CtrlFileType.create(file_type_payload)

    payload = %{
      module_role: HRand.random_numeric_string(),
      file_type: file_type.file_type
    }

    {:ok, payload: payload}
  end

  test "create/1", %{payload: payload} do
    assert {:ok, _} = CtrlModuleRole.create(payload)
  end

  describe "find/2" do
    test "success", %{payload: payload} do
      assert {:ok, role} = CtrlModuleRole.create(payload)
      assert {:ok, ^role} = CtrlModuleRole.find(role.module_role, role.file_type)
    end

    test "failure" do
      assert {:error, :notfound} = CtrlModuleRole.find("", "")
    end
  end

  test "delete/1 idempotency", %{payload: payload}  do
    assert {:ok, role} = CtrlModuleRole.create(payload)

    assert :ok = CtrlModuleRole.delete(role.module_role, role.file_type)
    assert :ok = CtrlModuleRole.delete(role.module_role, role.file_type)

    assert {:error, :notfound} = CtrlModuleRole.find(role.module_role, role.file_type)
  end
end