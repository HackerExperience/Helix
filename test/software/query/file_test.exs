defmodule Helix.Software.Query.FileTest do

  use Helix.Test.Case.Integration

  alias Helix.Software.Model.File
  alias Helix.Software.Query.File, as: FileQuery

  alias Helix.Test.Software.Setup, as: SoftwareSetup

  @moduletag :integration

  describe "fetch/1" do
    test "succeeds with valid input" do
      {file, _} = SoftwareSetup.file()

      entry = FileQuery.fetch(file.file_id)
      assert entry == file
    end

    test "fails when file doesn't exist" do
      refute FileQuery.fetch(File.ID.generate())
    end
  end

  describe "storage_contents/1" do
    test "succeeds with valid input" do
      {storage, _} = SoftwareSetup.storage()
      file_opts = [storage_id: storage.storage_id]
      gen_files = SoftwareSetup.random_files!(total: 3, file_opts: file_opts)

      contents = FileQuery.storage_contents(storage)

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

      refute Enum.empty?(FileQuery.files_on_storage(storage))
    end
  end

  describe "fetch_best/3" do
    @tag :pending  # Waiting `modules` refactor
    test "seila" do
      # {storage, _} = SoftwareSetup.storage()

      # storage_opts = [storage_id: storage.storage_id]

      # cracker1 = SoftwareSetup.cracker([bruteforce: 10] ++ storage_opts)
      # cracker2 = SoftwareSetup.cracker([bruteforce: 20] ++ storage_opts)
      # cracker3 = SoftwareSetup.cracker([bruteforce: 30] ++ storage_opts)

      # # Ensure all files are on the storage
      # files = FileQuery.files_on_storage(storage.storage_id)

      # best = FileQuery.fetch_best(storage, :cracker, :bruteforce)
    end
  end
end
