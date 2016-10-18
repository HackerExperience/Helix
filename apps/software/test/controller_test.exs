defmodule HELM.Software.ControllerTest do
  use ExUnit.Case

  alias HELF.Broker
  alias HELM.Software.Storage.Controller, as: SoftStorageCtrl
  alias HELM.Software.Storage.Drive.Controller, as: SoftStorageDriveCtrl
  alias HELM.Software.File.Type.Controller, as: SoftFileTypeCtrl
  alias HELM.Software.File.Controller, as: SoftFileCtrl
  alias HELM.Software.Module.Role.Controller, as: SoftModuleRoleCtrl

  def random_num do
    :rand.uniform(134217727)
  end

  def random_str do
    random_num()
    |> Integer.to_string
  end

  describe "HELM.Software.Storage.Controller" do
    test "create/0 success" do
      assert {:ok, _} = SoftStorageCtrl.create()
    end

    test "find/1 success" do
      {:ok, storage} = SoftStorageCtrl.create()
      assert {:ok, storage} = SoftStorageCtrl.find(storage.storage_id)
    end

    test "delete/1 success" do
      {:ok, storage} = SoftStorageCtrl.create()
      assert {:ok, _} = SoftStorageCtrl.delete(storage.storage_id)
    end
  end

  describe "HELM.Software.Storage.Drive.Controller" do
    test "create/2 success" do
      {:ok, storage} = SoftStorageCtrl.create()
      assert {:ok, _} = SoftStorageDriveCtrl.create(random_num, storage.storage_id)
    end

    test "find/1 success" do
      {:ok, storage} = SoftStorageCtrl.create()
      {:ok, drive} = SoftStorageDriveCtrl.create(random_num, storage.storage_id)
      assert {:ok, drive} = SoftStorageDriveCtrl.find(drive.drive_id)
    end

    test "delete/1 success" do
      {:ok, storage} = SoftStorageCtrl.create()
      {:ok, drive} = SoftStorageDriveCtrl.create(random_num, storage.storage_id)
      assert {:ok, _} = SoftStorageDriveCtrl.delete(drive.drive_id)
    end
  end

  describe "HELM.Software.File.Type.Controller" do
    test "create/2 success" do
      assert {:ok, _} = SoftFileTypeCtrl.create(random_str, ".test")
    end

    test "find/1 success" do
      {:ok, file} = SoftFileTypeCtrl.create(random_str, ".test")
      assert {:ok, file} = SoftFileTypeCtrl.find(file.file_type)
    end

    test "delete/1 success" do
      {:ok, file} = SoftFileTypeCtrl.create(random_str, ".test")
      assert {:ok, _} = SoftFileTypeCtrl.delete(file.file_type)
    end
  end

  describe "HELM.Software.File.Controller" do
    test "create/2 success" do
      {:ok, ftype} = SoftFileTypeCtrl.create(random_str, ".test")
      {:ok, stor} = SoftStorageCtrl.create()
      assert {:ok, _} = SoftFileCtrl.create(stor.storage_id, "/dev/null", "void",
                                            ftype.file_type, random_num)
    end

    test "find/1 success" do
      {:ok, ftype} = SoftFileTypeCtrl.create(random_str, ".test")
      {:ok, stor} = SoftStorageCtrl.create()
      {:ok, file} = SoftFileCtrl.create(stor.storage_id, "/dev/null", "void",
                                        ftype.file_type, random_num)
      assert {:ok, file} = SoftFileCtrl.find(file.file_id)
    end

    test "delete/1 success" do
      {:ok, ftype} = SoftFileTypeCtrl.create(random_str, ".test")
      {:ok, stor} = SoftStorageCtrl.create()
      {:ok, file} = SoftFileCtrl.create(stor.storage_id, "/dev/null", "void",
                                        ftype.file_type, random_num)
      assert {:ok, _} = SoftFileCtrl.delete(file.file_id)
    end
  end

  describe "HELM.Software.Module.Role.Controller" do
    test "create/2 success" do
      {:ok, ftype} = SoftFileTypeCtrl.create(random_str, ".test")
      assert {:ok, _} = SoftModuleRoleCtrl.create(random_str, ftype.file_type)
    end

    test "find/1 success" do
      {:ok, ftype} = SoftFileTypeCtrl.create(random_str, ".test")
      {:ok, role} = SoftModuleRoleCtrl.create(random_str, ftype.file_type)
      assert {:ok, role} = SoftModuleRoleCtrl.find(role.module_role, role.file_type)
    end

    test "delete/1 success" do
      {:ok, ftype} = SoftFileTypeCtrl.create(random_str, ".test")
      {:ok, role} = SoftModuleRoleCtrl.create(random_str, ftype.file_type)
      assert {:ok, _} = SoftModuleRoleCtrl.delete(role.module_role, role.file_type)
    end
  end
end
