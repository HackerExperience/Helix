defmodule HELM.Software.File.ControllerTest do
  use ExUnit.Case

  alias HELL.Random, as: HRand
  alias HELM.Software.File.Type.Controller, as: FileTypeCtrl
  alias HELM.Software.Storage.Controller, as: StorageCtrl
  alias HELM.Software.File.Controller, as: FileCtrl

  describe "creation" do
    test "success" do
      file_type = HRand.random_numeric_string()
      file_size = HRand.random_number()
      {:ok, ftype} = FileTypeCtrl.create(file_type, ".test")
      {:ok, stor} = StorageCtrl.create()
      assert {:ok, _} = FileCtrl.create(stor.storage_id, "/dev/null", "void",
                                        ftype.file_type, file_size)
    end
  end

  describe "search" do
    test "success" do
      file_type = HRand.random_numeric_string()
      file_size = HRand.random_number()
      {:ok, ftype} = FileTypeCtrl.create(file_type, ".test")
      {:ok, stor} = StorageCtrl.create()
      {:ok, file} = FileCtrl.create(stor.storage_id, "/dev/null", "void",
                                    ftype.file_type, file_size)
      assert {:ok, file} = FileCtrl.find(file.file_id)
    end
  end

  describe "update" do
    test "success" do
      file_type = HRand.random_numeric_string()
      file_size = HRand.random_number()

      old_name = "void"
      new_name = "null"

      old_path = "/dev/null"
      new_path = "/dev/random"

      {:ok, old_stor} = StorageCtrl.create()
      {:ok, new_stor} = StorageCtrl.create()

      {:ok, ftype} = FileTypeCtrl.create(file_type, ".test")
      {:ok, file} = FileCtrl.create(old_stor.storage_id, old_path, old_name, ftype.file_type, file_size)
      {:ok, new_file} = FileCtrl.update(file.file_id, %{name: new_name, file_path: new_path, storage_id: new_stor.storage_id})

      assert new_file.name == new_name
      assert new_file.file_path == new_path
      assert new_file.storage_id == new_stor.storage_id
    end
  end

  describe "removal" do
    test "success" do
      file_type = HRand.random_numeric_string()
      file_size = HRand.random_number()
      {:ok, ftype} = FileTypeCtrl.create(file_type, ".test")
      {:ok, stor} = StorageCtrl.create()
      {:ok, file} = FileCtrl.create(stor.storage_id, "/dev/null", "void",
                                 ftype.file_type, file_size)
      assert {:ok, _} = FileCtrl.delete(file.file_id)
    end
  end
end
