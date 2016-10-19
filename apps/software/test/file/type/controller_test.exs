defmodule HELM.Software.File.Type.ControllerTest do
  use ExUnit.Case

  alias HELL.Random, as: HRand
  alias HELM.Software.File.Type.Controller, as: FileTypeCtrl

  describe "creation" do
    test "success" do
      file_type = HRand.random_numeric_string()
      assert {:ok, _} = FileTypeCtrl.create(file_type, ".test")
    end
  end

  describe "search" do
    test "success" do
      file_type = HRand.random_numeric_string()
      {:ok, file} = FileTypeCtrl.create(file_type, ".test")
      assert {:ok, file} = FileTypeCtrl.find(file.file_type)
    end
  end

  describe "removal" do
    test "success" do
      file_type = HRand.random_numeric_string()
      {:ok, file} = FileTypeCtrl.create(file_type, ".test")
      assert {:ok, _} = FileTypeCtrl.delete(file.file_type)
    end
  end
end
