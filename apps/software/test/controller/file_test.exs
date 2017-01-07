defmodule Helix.Software.Controller.FileTest do

  use ExUnit.Case, async: true

  alias HELL.IPv6
  alias HELL.TestHelper.Random, as: HRand
  alias Helix.Software.Repo
  alias Helix.Software.Model.FileType, as: MdlFileType
  alias Helix.Software.Controller.Storage, as: CtrlStorage
  alias Helix.Software.Controller.File, as: CtrlFile

  @file_type HRand.string(min: 20)

  setup_all do
    %{file_type: @file_type, extension: ".test"}
    |> MdlFileType.create_changeset()
    |> Repo.insert!()

    :ok
  end

  setup do
    {:ok, storage} = CtrlStorage.create()

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
    assert {:ok, _} = CtrlFile.create(payload)
  end

  describe "find/1" do
    test "success", %{payload: payload} do
      assert {:ok, file} = CtrlFile.create(payload)
      assert {:ok, ^file} = CtrlFile.find(file.file_id)
    end

    test "failure" do
      assert {:error, :notfound} == CtrlFile.find(IPv6.generate([]))
    end
  end

  describe "update/2" do
    test "rename file", %{payload: payload} do
      payload2 = %{name: "null"}

      assert {:ok, file} = CtrlFile.create(payload)
      assert {:ok, file} = CtrlFile.update(file.file_id, payload2)

      assert payload2.name == file.name
    end

    test "move file", %{payload: payload} do
      payload2 = %{file_path: "/dev/urandom"}

      assert {:ok, file} = CtrlFile.create(payload)
      assert {:ok, file} = CtrlFile.update(file.file_id, payload2)

      assert payload2.file_path == file.file_path
    end

    test "change storage", %{payload: payload} do
      {:ok, update_storage} = CtrlStorage.create()

      payload2 = %{storage_id: update_storage.storage_id}

      assert {:ok, file} = CtrlFile.create(payload)
      assert {:ok, file} = CtrlFile.update(file.file_id, payload2)

      assert payload2.storage_id == file.storage_id
    end

    test "not found" do
      assert {:error, :notfound} == CtrlFile.update(IPv6.generate([]), %{})
    end
  end

  test "delete/1 idempotency", %{payload: payload} do
    assert {:ok, file} = CtrlFile.create(payload)
    assert :ok = CtrlFile.delete(file.file_id)
    assert :ok = CtrlFile.delete(file.file_id)
    assert {:error, :notfound} == CtrlFile.find(file.file_id)
  end
end