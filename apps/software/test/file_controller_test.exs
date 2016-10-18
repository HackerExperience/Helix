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

  describe "removal" do
    test "success" do
      file_type = HRand.random_numeric_string()
      file_size = HRand.random_number()
      {:ok, ftype} = FileTypeCtrl.create(file_type, ".test")
      {:ok, stor} = StorageCtrl.create()
      assert {:ok, _} = FileCtrl.create(stor.storage_id, "/dev/null", "void",
                                        ftype.file_type, file_size)
    end
  end
end
