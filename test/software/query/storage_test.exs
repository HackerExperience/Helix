defmodule Helix.Software.Query.StorageTest do

  use Helix.Test.Case.Integration

  alias Helix.Software.Model.File
  alias Helix.Software.Query.Storage, as: StorageQuery

  alias Helix.Test.Software.Setup, as: SoftwareSetup

  describe "storage_contents/1" do
    test "succeeds with valid input" do
      {storage, _} = SoftwareSetup.storage()
      file_opts = [storage_id: storage.storage_id]
      gen_files = SoftwareSetup.random_files!(total: 3, file_opts: file_opts)

      contents = StorageQuery.storage_contents(storage)

      files =
        contents
        |> Map.values()
        |> List.flatten()

      # asserts that it gets the expected number of files and that these
      # files are consistently grouped by their path
      assert Enum.count(gen_files) == Enum.count(files)

      expected = Enum.map(gen_files, &([path: &1.path, id: &1.file_id]))
      contents =
        contents
        |> Enum.map(fn {k, v} -> {k, Enum.map(v, &(&1.file_id))} end)
        |> :maps.from_list()

      assert Enum.all?(expected, &(&1[:id] in contents[&1[:path]]))
    end
  end

  describe "files_on_storage/1" do
    test "succeeds with valid input" do
      {storage, _} = SoftwareSetup.storage()
      file_opts = [storage_id: storage.storage_id]
      SoftwareSetup.random_files!(total: 3, file_opts: file_opts)

      refute Enum.empty?(StorageQuery.files_on_storage(storage))
    end
  end
end
