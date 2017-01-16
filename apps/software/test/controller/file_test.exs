defmodule Helix.Software.Controller.FileTest do

  use ExUnit.Case, async: true

  alias HELL.PK
  alias HELL.TestHelper.Random, as: HRand
  alias Helix.Software.Controller.File, as: FileController
  alias Helix.Software.Controller.Storage, as: StorageController
  alias Helix.Software.Model.FileType
  alias Helix.Software.Repo

  setup_all do
    file_type = create_file_type()
    {:ok, file_type: file_type}
  end

  setup %{file_type: file_type} do
    {:ok, s} = StorageController.create()
    payload = create_params(%{file_type: file_type, storage_id: s.storage_id})
    {:ok, payload: payload}
  end

  defp create_file_type() do
    file_type = HRand.string(min: 20)
    %{file_type: file_type, extension: ".test"}
    |> FileType.create_changeset()
    |> Repo.insert!()
    file_type
  end

  defp create_params(%{file_type: file_type, storage_id: storage_id}) do
    %{
      name: HRand.digits(min: 20),
      file_path: HRand.digits(min: 20),
      file_type: file_type,
      file_size: HRand.number(min: 1),
      storage_id: storage_id
    }
  end

  describe "file creation" do
    test "creates the file", %{payload: payload} do
      {:ok, file} = FileController.create(payload)
      {:ok, ^file} = FileController.find(file.file_id)

      assert payload.name == file.name
      assert payload.file_path == file.file_path
      assert payload.file_size == file.file_size
      assert payload.file_type == file.file_type
      assert payload.storage_id == file.storage_id
    end

    test "failure when file exists", %{payload: payload} do
      {:ok, _} = FileController.create(payload)
      assert {:error, :file_exists} == FileController.create(payload)
    end
  end

  describe "file fetching" do
    test "fetches the file", %{payload: payload} do
      {:ok, file} = FileController.create(payload)
      assert {:ok, ^file} = FileController.find(file.file_id)
    end

    test "failure when file doesn't exist" do
      assert {:error, :notfound} == FileController.find(PK.generate([]))
    end
  end

  describe "file update" do
    test "updates the file", %{payload: payload0} do
      {:ok, storage} = StorageController.create()

      payload1 = %{
        name: HRand.digits(min: 20),
        file_path: HRand.digits(min: 20),
        storage_id: storage.storage_id}

      {:ok, file0} = FileController.create(payload0)
      {:ok, file1} = FileController.update(file0.file_id, payload1)
      {:ok, ^file1} = FileController.find(file0.file_id)

      assert payload1.name == file1.name
      assert payload1.file_path == file1.file_path
      assert payload1.storage_id == file1.storage_id
    end

    test "fails when file doesn't exist" do
      assert {:error, :notfound} == FileController.update(PK.generate([]), %{})
    end

    test "fails when file exists", %{payload: payload0} do
      FileController.create(payload0)

      p = %{file_type: payload0.file_type, storage_id: payload0.storage_id}
      payload1 = create_params(p)
      {:ok, file1} = FileController.create(payload1)

      assert {:error, :file_exists} == FileController.update(file1.file_id, payload0)
      assert {:ok, ^file1} = FileController.find(file1.file_id)
    end
  end

  describe "renaming a file" do
    test "renames the file", %{payload: payload} do
      {:ok, file} = FileController.create(payload)
      new_name = Burette.Color.name()
      {:ok, renamed_file} = FileController.rename(file, new_name)
      {:ok, ^renamed_file} = FileController.find(renamed_file.file_id)

      assert new_name == renamed_file.name
    end

    test "fails to rename when file exists", %{payload: payload0} do
      {:ok, file0} = FileController.create(payload0)

      payload1 =
        %{file_type: payload0.file_type, storage_id: payload0.storage_id}
        |> create_params()
        |> Map.put(:file_path, payload0.file_path)

      {:ok, file1} = FileController.create(payload1)

      assert {:error, :file_exists} == FileController.rename(file1, file0.name)
      assert {:ok, ^file1} = FileController.find(file1.file_id)
    end
  end

  describe "moving a file" do
    test "moves the file", %{payload: payload} do
      {:ok, file} = FileController.create(payload)
      new_path = Burette.Color.name()
      {:ok, moved_file} = FileController.move(file, new_path)
      {:ok, ^moved_file} = FileController.find(file.file_id)

      assert new_path == moved_file.file_path
    end

    test "fails to move when file exists", %{payload: payload0} do
      {:ok, file0} = FileController.create(payload0)

      payload1 =
        %{file_type: payload0.file_type, storage_id: payload0.storage_id}
        |> create_params()
        |> Map.put(:name, payload0.name)
        |> Map.put(:file_path, payload0.name)

      {:ok, file1} = FileController.create(payload1)

      assert {:error, :file_exists} == FileController.move(file1, file0.file_path)
      assert {:ok, ^file1} = FileController.find(file1.file_id)
    end
  end

  describe "copying a file" do
    test "copies the file", %{payload: payload0} do
      {:ok, file0} = FileController.create(payload0)

      payload1 = %{
        storage_id: file0.storage_id,
        file_path: file0.file_path,
        name: Burette.Color.name()}

      {:ok, file1} = FileController.copy(file0, payload1)
      {:ok, ^file1} = FileController.find(file1.file_id)

      assert payload1.name == file1.name
      assert file0.file_path == file1.file_path
      assert file0.file_size == file1.file_size
      assert file0.file_type == file1.file_type
      assert file0.storage_id == file1.storage_id
    end

    test "fails to copy when file exists", %{payload: payload0} do
      {:ok, file} = FileController.create(payload0)

      payload1 = %{
        storage_id: file.storage_id,
        file_path: file.file_path,
        name: file.name}

      assert {:error, :file_exists} == FileController.copy(file, payload1)
      assert {:ok, ^file} = FileController.find(file.file_id)
    end
  end

  describe "deleting a file" do
    test "deletes the file", %{payload: payload} do
      {:ok, file} = FileController.create(payload)
      :ok = FileController.delete(file)
      :ok = FileController.delete(file)

      assert {:error, :notfound} == FileController.find(file.file_id)
    end

    test "deleting the file by it's id is idempotency", %{payload: payload} do
      {:ok, file} = FileController.create(payload)
      :ok = FileController.delete(file.file_id)
      :ok = FileController.delete(file.file_id)

      assert {:error, :notfound} == FileController.find(file.file_id)
    end
  end
end