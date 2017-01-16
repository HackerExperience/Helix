defmodule Helix.Software.Controller.FileTest do

  use ExUnit.Case, async: true

  alias HELL.PK
  alias HELL.TestHelper.Random, as: HRand
  alias Helix.Software.Controller.File, as: FileController
  alias Helix.Software.Controller.Storage, as: StorageController
  alias Helix.Software.Model.FileType
  alias Helix.Software.Repo

  setup_all do
    file_type = HRand.string(min: 20)
    %{file_type: file_type, extension: ".test"}
    |> FileType.create_changeset()
    |> Repo.insert!()

    {:ok, file_type: file_type}
  end

  setup %{file_type: file_type} do
    {:ok, s} = StorageController.create()
    payload = create_params(%{file_type: file_type, storage_id: s.storage_id})
    {:ok, payload: payload}
  end

  defp create_params(%{file_type: file_type, storage_id: storage_id}) do
    %{
      name: HRand.digits(min: 20),
      file_path: "/dev/null",
      file_type: file_type,
      file_size: HRand.number(min: 1),
      storage_id: storage_id
    }
  end

  describe "file creation" do
    test "creates the file", %{payload: payload} do
      assert {:ok, _} = FileController.create(payload)
    end

    test "failure when file exists", %{payload: payload} do
      FileController.create(payload)
      assert {:error, :file_exists} == FileController.create(payload)
    end
  end

  describe "find/1" do
    test "success", %{payload: payload} do
      assert {:ok, file} = FileController.create(payload)
      assert {:ok, ^file} = FileController.find(file.file_id)
    end

    test "failure" do
      assert {:error, :notfound} == FileController.find(PK.generate([]))
    end
  end

  describe "update/2" do
    test "rename file", %{payload: payload} do
      payload2 = %{name: "null"}

      assert {:ok, file} = FileController.create(payload)
      assert {:ok, file} = FileController.update(file.file_id, payload2)

      assert payload2.name == file.name
    end

    test "move file", %{payload: payload} do
      payload2 = %{file_path: "/dev/urandom"}

      assert {:ok, file} = FileController.create(payload)
      assert {:ok, file} = FileController.update(file.file_id, payload2)

      assert payload2.file_path == file.file_path
    end

    test "change storage", %{payload: payload} do
      {:ok, update_storage} = StorageController.create()

      payload2 = %{storage_id: update_storage.storage_id}

      assert {:ok, file} = FileController.create(payload)
      assert {:ok, file} = FileController.update(file.file_id, payload2)

      assert payload2.storage_id == file.storage_id
    end

    test "not found" do
      assert {:error, :notfound} == FileController.update(PK.generate([]), %{})
    end

    test "fails when file exists", %{payload: payload0} do
      FileController.create(payload0)

      p = %{file_type: payload0.file_type, storage_id: payload0.storage_id}
      payload1 = create_params(p)
      {:ok, file1} = FileController.create(payload1)

      assert {:error, :file_exists} == FileController.update(file1.file_id, payload0)
    end
  end

  describe "renaming a file" do
    test "renames the file", %{payload: payload} do
      {:ok, file} = FileController.create(payload)
      new_name = Burette.Color.name()
      {:ok, renamed_file} = FileController.rename(file, new_name)

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
    end
  end

  describe "moving a file" do
    test "moves the file", %{payload: payload} do
      {:ok, file} = FileController.create(payload)
      new_path = Burette.Color.name()
      {:ok, moved_file} = FileController.move(file, new_path)

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
    end
  end

  describe "copying a file" do
    test "copies the file", %{payload: payload0} do
      {:ok, file} = FileController.create(payload0)
      payload1 = %{
        storage_id: file.storage_id,
        file_path: file.file_path,
        name: Burette.Color.name()}

      assert {:ok, _} = FileController.copy(file, payload1)
    end

    test "fails to copy when file exists", %{payload: payload0} do
      {:ok, file} = FileController.create(payload0)
      payload1 = %{
        storage_id: file.storage_id,
        file_path: file.file_path,
        name: file.name}

      assert {:error, :file_exists} == FileController.copy(file, payload1)
    end
  end

  test "delete/1 idempotency", %{payload: payload} do
    assert {:ok, file} = FileController.create(payload)
    assert :ok = FileController.delete(file.file_id)
    assert :ok = FileController.delete(file.file_id)
    assert {:error, :notfound} == FileController.find(file.file_id)
  end
end