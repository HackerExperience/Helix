defmodule Helix.Software.Controller.FileTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Software.Controller.File, as: FileController
  alias Helix.Software.Model.File
  alias Helix.Software.Model.SoftwareModule
  alias Helix.Software.Repo

  alias Helix.Software.Factory

  @moduletag :integration

  def generate_params do
    storage = Factory.insert(:storage)
    file = Factory.build(:file)

    file
    |> Map.take([:path, :file_size, :name, :software_type])
    |> Map.put(:storage_id, storage.storage_id)
  end

  defp generate_software_modules(software_type) do
    software_type
    |> SoftwareModule.Query.by_software_type()
    |> Repo.all()
    |> Enum.into(%{}, &{&1.software_module, Burette.Number.number(1..1024)})
  end

  describe "creating" do
    test "succeeds with valid params" do
      params = generate_params()
      {:ok, file} = FileController.create(params)

      got = Map.take(file, Map.keys(params))
      assert params == got
    end

    test "fails on path identity conflict" do
      params = generate_params()
      collision = Map.take(params, [:name, :path, :software_type, :storage_id])

      {:ok, _} = FileController.create(params)

      params = Map.merge(generate_params(), collision)
      assert {:error, :file_exists} == FileController.create(params)
    end
  end

  describe "fetching" do
    test "returns a record based on its identification" do
      file = Factory.insert(:file)
      assert %File{} = FileController.fetch(file.file_id)
    end

    test "returns nil if file doesn't exist" do
      refute FileController.fetch(Random.pk())
    end
  end

  describe "updating" do
    # TODO: Chop the things that are tested here in three different tests
    test "succeeds with valid params" do
      file = Factory.insert(:file)

      # update name
      params = Map.take(Factory.params_for(:file), [:name])
      {:ok, updated} = FileController.update(file, params)

      refute file.name == updated.name
      assert params.name == updated.name

      # update path
      params = Map.take(Factory.params_for(:file), [:path])
      {:ok, updated} = FileController.update(file, params)

      refute file.path == updated.path
      assert params.path == updated.path
    end

    test "fails on file path identity conflict" do
      file0 = Factory.insert(:file)
      intersection = Map.take(file0, [:storage, :software_type])
      file1 = Factory.insert(:file, intersection)

      params = Map.take(file0, [:path, :name])
      assert {:error, :file_exists} == FileController.update(file1, params)
    end
  end

  describe "copying" do
    test "to another path in the same storage" do
      path = Factory.params_for(:file).path
      origin = Factory.insert(:file)

      {:ok, copy} = FileController.copy(origin, path, origin.storage_id)

      assert FileController.fetch(origin.file_id)
      assert FileController.fetch(copy.file_id)
      assert path == copy.path
    end

    test "to another storage" do
      storage = Factory.insert(:storage)
      origin = Factory.insert(:file)

      {:ok, copy} =
        FileController.copy(origin, origin.path, storage.storage_id)

      assert FileController.fetch(origin.file_id)
      assert FileController.fetch(copy.file_id)
      assert storage.storage_id == copy.storage_id
    end

    test "fails on path identity conflict" do
      origin = Factory.insert(:file)

      result = FileController.copy(origin, origin.path, origin.storage_id)
      assert {:error, :file_exists} == result
    end
  end

  describe "moving" do
    test "to another path" do
      file = Factory.insert(:file)
      path = Factory.params_for(:file).path

      {:ok, file} = FileController.move(file, path, file.storage_id)

      assert path == file.path
    end

    test "fails on path identity conflict" do
      file0 = Factory.insert(:file)
      similarities = Map.take(file0, [:name, :storage, :software_type])
      file1 = Factory.insert(:file, similarities)

      result = FileController.move(file1, file0.path, file0.storage_id)
      assert {:error, :file_exists} == result
    end
  end

  describe "renaming" do
    test "succeeds with a valid non-conflicting name" do
      file = Factory.insert(:file)
      name = Factory.params_for(:file).name

      {:ok, file} = FileController.rename(file, name)

      assert name == file.name
    end

    test "fails on path identity conflict" do
      file0 = Factory.insert(:file)
      similarities = Map.take(file0, [:path, :software_type, :storage])
      file1 = Factory.insert(:file, similarities)

      assert {:error, :file_exists} == FileController.rename(file1, file0.name)
    end
  end

  test "setting modules" do
    file = Factory.insert(:file)
    modules = generate_software_modules(file.software_type)

    {:ok, file_modules} = FileController.set_modules(file, modules)

    # created modules from `modules`
    assert modules == file_modules
  end

  describe "getting modules" do
    test "returns file modules as a map" do
      file = Factory.insert(:file)
      modules = generate_software_modules(file.software_type)

      FileController.set_modules(file, modules)

      file_modules = FileController.get_modules(file)
      assert modules == file_modules
    end

    test "returns empty map when nothing is found" do
      file = Factory.insert(:file)
      file_modules = FileController.get_modules(file)

      assert Enum.empty?(file_modules)
    end
  end

  describe "deleting" do
    test "is idempotent" do
      file = Factory.insert(:file)

      assert FileController.fetch(file.file_id)
      FileController.delete(file.file_id)
      FileController.delete(file.file_id)
      refute FileController.fetch(file.file_id)
    end

    test "can be done by its id" do
      file = Factory.insert(:file)

      assert FileController.fetch(file.file_id)
      FileController.delete(file.file_id)
      refute FileController.fetch(file.file_id)
    end

    test "can be done by its struct" do
      file = Factory.insert(:file)

      assert FileController.fetch(file.file_id)
      FileController.delete(file.file_id)
      refute FileController.fetch(file.file_id)
    end

    test "deletes every module" do
      file = Factory.insert(:file)
      software_module = generate_software_modules(file.software_type)

      {:ok, _} = FileController.set_modules(file, software_module)

      Repo.delete(file)

      file_modules = FileController.get_modules(file)
      assert Enum.empty?(file_modules)
    end
  end
end
