defmodule Helix.Software.Controller.FileTextTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Software.Controller.File, as: FileController
  alias Helix.Software.Controller.FileText, as: FileTextController
  alias Helix.Software.Model.FileText

  alias Helix.Software.Factory

  @moduletag :integration

  def generate_path do
    1..5
    |> Random.repeat(&Random.username/0)
    |> Enum.join("/")
    |> String.replace_prefix("", "/")
  end

  describe "create/1" do
    test "will create a file for the text on storage" do
      storage = Factory.insert(:storage)

      params = %{
        name: Random.username(),
        path: generate_path(),
        contents: Random.string(max: 100)
      }

      assert {:ok, file_text} = FileTextController.create(storage, params)
      assert FileController.fetch(file_text.file_id)
    end
  end

  describe "fetch/1" do
    test "succeeds by id" do
      file_text = Factory.insert(:file_text)
      assert %FileText{} = FileTextController.fetch(file_text.file_id)
    end

    test "fails when file_text doesn't exist" do
      refute FileTextController.fetch(Random.pk())
    end
  end

  describe "update_contents/2" do
    test "succeeds with valid input" do
      file_text = Factory.insert(:file_text)
      result =  FileTextController.update_contents(file_text, "example text")

      assert {:ok, %FileText{}} = result
    end
  end
end
