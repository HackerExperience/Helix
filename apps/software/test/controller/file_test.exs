defmodule Helix.Software.Controller.FileTest do

  use ExUnit.Case, async: true

  alias HELL.PK
  alias HELL.TestHelper.Random
  alias Helix.Software.Controller.File, as: FileController
  alias Helix.Software.Controller.Storage, as: StorageController
  alias Helix.Software.Model.FileType
  alias Helix.Software.Repo

  setup_all do
    file_type = Random.string(min: 20)
    extension = Random.string(min: 1, max: 3)

    %{file_type: file_type, extension: "." <> extension}
    |> FileType.create_changeset()
    |> Repo.insert!()

    {:ok, file_type: file_type}
  end

  setup do
    {:ok, storage} = StorageController.create()
    {:ok, storage: storage}
  end

  defp generate_payload(file_type, storage) do
    %{
      name: generate_name(),
      file_path: generate_path(),
      file_type: file_type,
      file_size: Random.number(min: 1),
      storage_id: storage.storage_id
    }
  end

  defp generate_name() do
    Random.digits(min: 20)
  end

  defp generate_path() do
    size = Random.number(1..10)
    alphabet = HELL.TestHelper.Random.Alphabet.Alphanum.alphabet
    random_str = fn _ ->
      length = Random.number(1..10)
      Random.string(length: length, alphabet: alphabet)
    end
    0..size
    |> Enum.map(random_str)
    |> Enum.join(".")
  end

  describe "file creation" do
    test "creates a file with the correct name", context do
      params = generate_payload(context.file_type, context.storage)
      {:ok, file1} = FileController.create(params)
      {:ok, file2} = FileController.find(file1.file_id)

      # file got the correct name
      assert params.name == file1.name

      # found file is identical to the one yielded by create
      assert file1 == file2
    end

    test "creates a file with the correct path", context do
      params = generate_payload(context.file_type, context.storage)
      {:ok, file1} = FileController.create(params)
      {:ok, file2} = FileController.find(file1.file_id)

      # file got the correct file_path
      assert params.file_path == file2.file_path

      # found file is identical to the one yielded by create
      assert file1 == file2
    end

    test "creates a file with the correct size", context do
      params = generate_payload(context.file_type, context.storage)
      {:ok, file1} = FileController.create(params)
      {:ok, file2} = FileController.find(file1.file_id)

      # file got the correct file_size
      assert params.file_size == file2.file_size

      # found file is identical to the one yielded by create
      assert file1 == file2
    end

    test "creates a file with the correct type", context do
      params = generate_payload(context.file_type, context.storage)
      {:ok, file1} = FileController.create(params)
      {:ok, file2} = FileController.find(file1.file_id)

      # file got the correct file_type
      assert params.file_type == file1.file_type

      # found file is identical to the one yielded by create
      assert file1 == file2
    end

    test "creates a file bound to the correct storage", context do
      params = generate_payload(context.file_type, context.storage)
      {:ok, file1} = FileController.create(params)
      {:ok, file2} = FileController.find(file1.file_id)

      # file got the correct storage
      assert context.storage.storage_id == file1.storage_id

      # found file is identical to the one yielded by create
      assert file1 == file2
    end

    test "create fails on path identity conflict", context do
      params = generate_payload(context.file_type, context.storage)
      {:ok, _} = FileController.create(params)

      # got expected error
      assert {:error, :file_exists} == FileController.create(params)
    end
  end

  describe "file fetching" do
    test "fetches an existent file", context do
      params = generate_payload(context.file_type, context.storage)
      {:ok, file1} = FileController.create(params)
      {:ok, file2} = FileController.find(file1.file_id)

      # found the same previously created file
      assert file1 == file2
    end

    test "find fails when files is not found" do
      # got expected error
      assert {:error, :notfound} == FileController.find(PK.generate([]))
    end
  end

  describe "file updating" do
    test "updates the name", context do
      params1 = generate_payload(context.file_type, context.storage)
      params2 = generate_payload(context.file_type, context.storage)
      {:ok, file1} = FileController.create(params1)
      {:ok, file1} = FileController.update(file1, params2)
      {:ok, file2} = FileController.find(file1.file_id)

      # file updates to the correct name
      assert params2.name == file1.name

      # file is identical to the one yielded by update
      assert file1 == file2
    end

    test "updates the path", context do
      params1 = generate_payload(context.file_type, context.storage)
      params2 = generate_payload(context.file_type, context.storage)
      {:ok, file1} = FileController.create(params1)
      {:ok, file1} = FileController.update(file1, params2)
      {:ok, file2} = FileController.find(file1.file_id)

      # file updates to the correct file_path
      assert params2.file_path == file1.file_path

      # file is identical to the one yielded by update
      assert file1 == file2
    end

    test "updates the storage", context do
      {:ok, storage} = StorageController.create()
      params1 = generate_payload(context.file_type, context.storage)
      params2 = generate_payload(context.file_type, storage)
      {:ok, file1} = FileController.create(params1)
      {:ok, file1} = FileController.update(file1, params2)
      {:ok, file2} = FileController.find(file1.file_id)

      # file updates to the correct storage_id
      assert storage.storage_id == file1.storage_id

      # file is identical to the one yielded by update
      assert file1 == file2
    end

    test "update fails on path identity conflict", context do
      params1 = generate_payload(context.file_type, context.storage)
      params2 = generate_payload(context.file_type, context.storage)
      {:ok, _} = FileController.create(params1)
      {:ok, file1} = FileController.create(params2)

      # got expected error
      assert {:error, :file_exists} == FileController.update(file1, params1)

      {:ok, file2} = FileController.find(file1.file_id)

      # file is unchanged
      assert file1 == file2
    end
  end

  describe "file copying" do
    test "copies to another path", context do
      params = generate_payload(context.file_type, context.storage)
      file_path = generate_path()
      storage_id = context.storage.storage_id
      {:ok, file1} = FileController.create(params)
      {:ok, file2} = FileController.copy(file1, file_path, storage_id)
      {:ok, file3} = FileController.find(file1.file_id)
      {:ok, file4} = FileController.find(file2.file_id)

      # original file remains unchanged
      assert file1 == file3

      # the new file was copied to the correct file_path
      assert file_path == file2.file_path

      # found file is identical to the one yielded by copy
      assert file2 == file4
    end

    test "copies to another storage", context do
      params = generate_payload(context.file_type, context.storage)
      {:ok, s} = StorageController.create()
      {:ok, file1} = FileController.create(params)
      {:ok, file2} = FileController.copy(file1, file1.file_path, s.storage_id)
      {:ok, file3} = FileController.find(file1.file_id)
      {:ok, file4} = FileController.find(file2.file_id)

      # original file remains unchanged
      assert file1 == file3

      # the new file was copied to the correct file_path
      assert s.storage_id == file2.storage_id

      # found file is identical to the one yielded by copy
      assert file2 == file4
    end

    test "copy fails on path identity conflict", context do
      params1 = generate_payload(context.file_type, context.storage)
      params2 =
        context.file_type
        |> generate_payload(context.storage)
        |> Map.put(:name, params1.name)
      file_path = params1.file_path
      storage_id = params1.storage_id

      {:ok, _} = FileController.create(params1)
      {:ok, file1} = FileController.create(params2)

      # got expected error
      assert {:error, :file_exists} ==
        FileController.copy(file1, file_path, storage_id)

      {:ok, file2} = FileController.find(file1.file_id)

      # file is unchanged
      assert file1 == file2
    end
  end

  describe "file moving" do
    test "moves to another path", context do
      params = generate_payload(context.file_type, context.storage)
      file_path = generate_path()
      storage_id = context.storage.storage_id
      {:ok, file1} = FileController.create(params)
      {:ok, file1} = FileController.move(file1, file_path, storage_id)
      {:ok, file2} = FileController.find(file1.file_id)

      # moved to the correct file_path
      assert file_path == file1.file_path

      # found file is identical to the one yielded by move
      assert file1 == file2
    end

    test "moves to to another storage", context do
      params = generate_payload(context.file_type, context.storage)
      {:ok, s} = StorageController.create()
      {:ok, file1} = FileController.create(params)
      {:ok, file1} = FileController.move(file1, file1.file_path, s.storage_id)
      {:ok, file2} = FileController.find(file1.file_id)

      # moved to the correct storage_id
      assert s.storage_id == file1.storage_id

      # found file is identical to the one yielded by move
      assert file1 == file2
    end

    test "move fails on path identity conflict", context do
      params1 = generate_payload(context.file_type, context.storage)
      params2 =
        context.file_type
        |> generate_payload(context.storage)
        |> Map.put(:name, params1.name)
      file_path = params1.file_path
      storage_id = params1.storage_id

      {:ok, _} = FileController.create(params1)
      {:ok, file1} = FileController.create(params2)

      # move yields expected error
      assert {:error, :file_exists} ==
        FileController.move(file1, file_path, storage_id)

      {:ok, file2} = FileController.find(file1.file_id)

      # file remains unchanged
      assert file1 == file2
    end
  end

  describe "file renaming" do
    test "ranames the file", context do
      params = generate_payload(context.file_type, context.storage)
      name = generate_name()
      {:ok, file1} = FileController.create(params)
      {:ok, file1} = FileController.rename(file1, name)
      {:ok, file2} = FileController.find(file1.file_id)

      # renamed the file correctly
      assert name == file1.name

      # found file is identical to the one yielded by rename
      assert file1 == file2
    end

    test "rename fails on path identity conflict", context do
      params1 = generate_payload(context.file_type, context.storage)
      params2 = Map.put(params1, :name, generate_name())

      {:ok, _} = FileController.create(params1)
      {:ok, file1} = FileController.create(params2)

      # got expected error
      assert {:error, :file_exists} == FileController.rename(file1, params1.name)

      {:ok, file2} = FileController.find(file1.file_id)

      # file remains unchanged
      assert file1 == file2
    end
  end

  describe "file deleting" do
    test "delete is idempotent", context do
      params = generate_payload(context.file_type, context.storage)
      {:ok, file} = FileController.create(params)
      :ok = FileController.delete(file)
      :ok = FileController.delete(file.file_id)

      # no file is found
      assert {:error, :notfound} == FileController.find(file.file_id)
    end

    test "deletes the file by id", context do
      params = generate_payload(context.file_type, context.storage)
      {:ok, file} = FileController.create(params)
      :ok = FileController.delete(file.file_id)

      # no file is found
      assert {:error, :notfound} == FileController.find(file.file_id)
    end

    test "deletes the file by struct", context do
      params = generate_payload(context.file_type, context.storage)
      {:ok, file} = FileController.create(params)
      :ok = FileController.delete(file)

      # no file is found
      assert {:error, :notfound} == FileController.find(file.file_id)
    end
  end
end