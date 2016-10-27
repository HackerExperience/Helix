defmodule HELM.Software.Controller.FileTypeTest do
  use ExUnit.Case

  alias HELL.Random, as: HRand
  alias HELM.Software.Controller.FileType, as: CtrlFileType

  describe "creation" do
    test "success" do
      file_type = HRand.random_numeric_string()
      assert {:ok, _} = CtrlFileType.create(file_type, ".test")
    end
  end

  describe "search" do
    test "success" do
      file_type = HRand.random_numeric_string()
      {:ok, file} = CtrlFileType.create(file_type, ".test")
      assert {:ok, ^file} = CtrlFileType.find(file.file_type)
    end
  end

  describe "removal" do
    test "success" do
      file_type = HRand.random_numeric_string()
      {:ok, file} = CtrlFileType.create(file_type, ".test")
      assert {:ok, _} = CtrlFileType.delete(file.file_type)
    end
  end
end