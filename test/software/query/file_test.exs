defmodule Helix.Software.Query.FileTest do

  use Helix.Test.IntegrationCase

  alias HELL.TestHelper.Random
  alias Helix.Software.Model.File
  alias Helix.Software.Query.File, as: FileQuery

  alias Helix.Software.Factory

  @moduletag :integration

  def generate_path do
    1..5
    |> Random.repeat(&Random.username/0)
    |> Enum.join("/")
    |> String.replace_prefix("", "/")
  end

  describe "fetch/1" do
    test "succeeds with valid input" do
      file = Factory.insert(:file)
      assert %File{} = FileQuery.fetch(file.file_id)
    end

    test "fails when file doesn't exist" do
      refute FileQuery.fetch(File.ID.generate())
    end
  end

  describe "storage_contents/1" do
    test "succeeds with valid input" do
      storage = Factory.insert(:storage)

      contents = FileQuery.storage_contents(storage)

      files =
        contents
        |> Map.values()
        |> List.flatten()

      # asserts that it gets the expected number of files and that these
      # files are consistently grouped by their path
      assert Enum.count(storage.files) == Enum.count(files)
      assert Enum.all?(storage.files, &(&1 in contents[&1.path]))
    end
  end

  describe "files_on_storage/1" do
    test "succeeds with valid input" do
      storage = Factory.insert(:storage)
      refute Enum.empty?(FileQuery.files_on_storage(storage))
    end
  end
end
