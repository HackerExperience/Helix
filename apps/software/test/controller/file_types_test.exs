defmodule HELM.Software.Controller.FileTypesTest do
  use ExUnit.Case

  alias HELL.Random, as: HRand
  alias HELM.Software.Controller.FileTypes, as: CtrlFileTypes

  describe "creation" do
    test "success" do
      file_type = HRand.random_numeric_string()
      assert {:ok, _} = CtrlFileTypes.create(file_type, ".test")
    end
  end

  describe "search" do
    test "success" do
      file_type = HRand.random_numeric_string()
      {:ok, file} = CtrlFileTypes.create(file_type, ".test")
      assert {:ok, ^file} = CtrlFileTypes.find(file.file_type)
    end
  end

  describe "removal" do
    test "success" do
      file_type = HRand.random_numeric_string()
      {:ok, file} = CtrlFileTypes.create(file_type, ".test")
      assert {:ok, _} = CtrlFileTypes.delete(file.file_type)
    end
  end
end