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
    test "holds the correct name", context do
      params = generate_payload(context.file_type, context.storage)
      {:ok, file} = FileController.create(params)

      assert {:ok, ^file} = FileController.find(file.file_id)
      assert params.file_path == file.file_path
    end

    test "uses the correct path", context do
      params = generate_payload(context.file_type, context.storage)
      {:ok, file} = FileController.create(params)

      assert {:ok, ^file} = FileController.find(file.file_id)
      assert params.file_path == file.file_path
    end

    test "uses the correct size", context do
      params = generate_payload(context.file_type, context.storage)
      {:ok, file} = FileController.create(params)

      assert {:ok, ^file} = FileController.find(file.file_id)
      assert params.file_size == file.file_size
    end

    test "uses the correct type", context do
      params = generate_payload(context.file_type, context.storage)
      {:ok, file} = FileController.create(params)

      assert {:ok, ^file} = FileController.find(file.file_id)
      assert params.file_type == file.file_type
    end

    test "is bound to storage", context do
      params = generate_payload(context.file_type, context.storage)
      {:ok, file} = FileController.create(params)

      assert {:ok, ^file} = FileController.find(file.file_id)
      assert context.storage.storage_id == file.storage_id
    end

    test "fails when file exists", context do
      params = generate_payload(context.file_type, context.storage)
      {:ok, _} = FileController.create(params)

      assert {:error, :file_exists} == FileController.create(params)
    end
  end

  describe "file fetching" do
    test "fetches an existent file", context do
      params = generate_payload(context.file_type, context.storage)
      {:ok, file} = FileController.create(params)
      assert {:ok, ^file} = FileController.find(file.file_id)
    end

    test "fails when files is not found" do
      assert {:error, :notfound} == FileController.find(PK.generate([]))
    end
  end

  describe "file updating" do
    test "updates the name", context do
      params1 = generate_payload(context.file_type, context.storage)
      params2 = generate_payload(context.file_type, context.storage)
      {:ok, file} = FileController.create(params1)
      {:ok, file} = FileController.update(file, params2)

      assert {:ok, ^file} = FileController.find(file.file_id)
      assert params2.file_path == file.file_path
    end

    test "updates the path", context do
      params1 = generate_payload(context.file_type, context.storage)
      params2 = generate_payload(context.file_type, context.storage)
      {:ok, file} = FileController.create(params1)
      {:ok, file} = FileController.update(file, params2)

      assert {:ok, ^file} = FileController.find(file.file_id)
      assert params2.file_path == file.file_path
    end

    test "updates the storage", context do
      {:ok, storage} = StorageController.create()
      params1 = generate_payload(context.file_type, context.storage)
      params2 = generate_payload(context.file_type, storage)
      {:ok, file} = FileController.create(params1)
      {:ok, file} = FileController.update(file, params2)

      assert {:ok, ^file} = FileController.find(file.file_id)
      assert storage.storage_id == file.storage_id
    end

    test "fails when file exists", context do
      params1 = generate_payload(context.file_type, context.storage)
      params2 = generate_payload(context.file_type, context.storage)
      {:ok, _} = FileController.create(params1)
      {:ok, file} = FileController.create(params2)

      assert {:error, :file_exists} == FileController.update(file, params1)
      assert {:ok, ^file} = FileController.find(file.file_id)
    end
  end

  describe "file copying" do
    test "copies to another path", context do
      params = generate_payload(context.file_type, context.storage)
      file_path = generate_path()
      storage_id = context.storage.storage_id
      {:ok, file} = FileController.create(params)
      {:ok, file} = FileController.copy(file, file_path, storage_id)

      assert {:ok, ^file} = FileController.find(file.file_id)
      assert file_path == file.file_path
    end

    test "copies to another storage", context do
      params = generate_payload(context.file_type, context.storage)
      {:ok, s} = StorageController.create()
      {:ok, file} = FileController.create(params)
      {:ok, file} = FileController.copy(file, file.file_path, s.storage_id)

      assert {:ok, ^file} = FileController.find(file.file_id)
      assert s.storage_id == file.storage_id
    end

    test "fails when file exists", context do
      params1 = generate_payload(context.file_type, context.storage)
      params2 =
        context.file_type
        |> generate_payload(context.storage)
        |> Map.put(:name, params1.name)
      file_path = params1.file_path
      storage_id = params1.storage_id

      {:ok, _} = FileController.create(params1)
      {:ok, file} = FileController.create(params2)

      assert {:error, :file_exists} =
        FileController.copy(file, file_path, storage_id)
    end
  end

  describe "file moving" do
    test "moves to another path", context do
      params = generate_payload(context.file_type, context.storage)
      file_path = generate_path()
      storage_id = context.storage.storage_id
      {:ok, file} = FileController.create(params)
      {:ok, file} = FileController.move(file, file_path, storage_id)

      assert {:ok, ^file} = FileController.find(file.file_id)
      assert file_path == file.file_path
    end

    test "moves to to another storage", context do
      params = generate_payload(context.file_type, context.storage)
      {:ok, s} = StorageController.create()
      {:ok, file} = FileController.create(params)
      {:ok, file} = FileController.move(file, file.file_path, s.storage_id)

      assert {:ok, ^file} = FileController.find(file.file_id)
      assert s.storage_id == file.storage_id
    end

    test "fails when file exists", context do
      params1 = generate_payload(context.file_type, context.storage)
      params2 =
        context.file_type
        |> generate_payload(context.storage)
        |> Map.put(:name, params1.name)
      file_path = params1.file_path
      storage_id = params1.storage_id

      {:ok, _} = FileController.create(params1)
      {:ok, file} = FileController.create(params2)

      assert {:error, :file_exists} =
        FileController.move(file, file_path, storage_id)
    end
  end

  describe "file renaming" do
    test "ranames the file", context do
      params = generate_payload(context.file_type, context.storage)
      name = generate_name()
      {:ok, file} = FileController.create(params)
      {:ok, file} = FileController.rename(file, name)

      assert {:ok, ^file} = FileController.find(file.file_id)
      assert name == file.name
    end

    test "fails when file exits", context do
      params1 = generate_payload(context.file_type, context.storage)
      params2 = Map.put(params1, :name, generate_name())
      {:ok, _} = FileController.create(params1)
      {:ok, file} = FileController.create(params2)

      assert {:error, :file_exists} == FileController.rename(file, params1.name)
      assert {:ok, ^file} = FileController.find(file.file_id)
    end
  end

  describe "file deleting" do
    test "is idempotent by id", context do
      params = generate_payload(context.file_type, context.storage)
      {:ok, file} = FileController.create(params)
      :ok = FileController.delete(file.file_id)
      :ok = FileController.delete(file.file_id)

      assert {:error, :notfound} == FileController.find(file.file_id)
    end

    test "is idempotent by struct", context do
      params = generate_payload(context.file_type, context.storage)
      {:ok, file} = FileController.create(params)
      :ok = FileController.delete(file)
      :ok = FileController.delete(file)

      assert {:error, :notfound} == FileController.find(file.file_id)
    end
  end
end