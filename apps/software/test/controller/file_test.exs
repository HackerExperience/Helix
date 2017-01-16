defmodule Helix.Software.Controller.FileTest do

  use ExUnit.Case, async: true

  alias HELL.PK
  alias HELL.TestHelper.Random, as: HRand
  alias Helix.Software.Controller.File, as: FileController
  alias Helix.Software.Controller.Storage, as: StorageController
  alias Helix.Software.Model.FileType
  alias Helix.Software.Repo

  @file_type HRand.string(min: 20)

  setup_all do
    %{file_type: @file_type, extension: ".test"}
    |> FileType.create_changeset()
    |> Repo.insert!()

    :ok
  end

  setup do
    {:ok, storage} = StorageController.create()

    payload = %{
      name: "void",
      file_path: "/dev/null",
      file_type: @file_type,
      file_size: HRand.number(min: 1),
      storage_id: storage.storage_id
    }

    {:ok, payload: payload}
  end

  test "create/1", %{payload: payload} do
    assert {:ok, _} = FileController.create(payload)
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
  end

  test "rename file", %{payload: payload} do
    {:ok, file} = FileController.create(payload)
    new_name = Burette.Color.name()
    {:ok, renamed_file} = FileController.rename(file, new_name)

    assert new_name == renamed_file.name
  end

  test "move file", %{payload: payload} do
    {:ok, file} = FileController.create(payload)
    new_path = Burette.Color.name()
    {:ok, moved_file} = FileController.move(file, new_path)

    assert new_path == moved_file.file_path
  end

  test "delete/1 idempotency", %{payload: payload} do
    assert {:ok, file} = FileController.create(payload)
    assert :ok = FileController.delete(file.file_id)
    assert :ok = FileController.delete(file.file_id)
    assert {:error, :notfound} == FileController.find(file.file_id)
  end
end