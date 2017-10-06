defmodule Helix.Software.Internal.FileTest do

  use Helix.Test.Case.Integration

  alias Helix.Software.Internal.File, as: FileInternal
  alias Helix.Software.Model.File
  alias Helix.Software.Model.SoftwareModule
  alias Helix.Software.Repo

  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Software.Factory
  alias Helix.Test.Software.Helper, as: SoftwareHelper
  alias Helix.Test.Software.Setup, as: SoftwareSetup

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
      {:ok, file} = FileInternal.create(params)

      got = Map.take(file, Map.keys(params))
      assert params == got
    end

    test "fails on path identity conflict" do
      params = generate_params()
      collision = Map.take(params, [:name, :path, :software_type, :storage_id])

      {:ok, _} = FileInternal.create(params)

      params = Map.merge(generate_params(), collision)

      {:error, result} = FileInternal.create(params)
      assert :full_path in Keyword.keys(result.errors)
    end
  end

  describe "fetching" do
    test "returns a record based on its identification" do
      file = Factory.insert(:file)
      assert %File{} = FileInternal.fetch(file.file_id)
    end

    test "returns nil if file doesn't exist" do
      refute FileInternal.fetch(File.ID.generate())
    end
  end

  describe "get_files_on_target_storage/1" do
    test "returns non-encrypted files" do
      target_storage = Factory.insert(:storage, %{files: []})
      Factory.insert_list(5, :file, storage: target_storage)

      files = FileInternal.get_files_on_target_storage(target_storage)

      assert 5 == Enum.count(files)
      assert Enum.all?(files, &(is_nil(&1.crypto_version)))
    end

    test "returns encrypted files" do
      target_storage = Factory.insert(:storage, files: [])
      Factory.insert_list(5, :file, storage: target_storage, crypto_version: 1)

      files = FileInternal.get_files_on_target_storage(target_storage)

      assert 5 == Enum.count(files)
      assert Enum.all?(files, &(not is_nil(&1.crypto_version)))
    end
  end

  describe "updating" do
    # TODO: Chop the things that are tested here in three different tests
    test "succeeds with valid params" do
      file = Factory.insert(:file)

      # update name
      params = %{name: "some very random name"}
      {:ok, updated} = FileInternal.update(file, params)

      refute file.name == updated.name
      assert params.name == updated.name

      # update path
      params = %{path: "/foo/bar"}
      {:ok, updated} = FileInternal.update(file, params)

      refute file.path == updated.path
      assert params.path == updated.path
    end

    test "fails on file path identity conflict" do
      file0 = Factory.insert(:file)
      intersection = Map.take(file0, [:storage, :software_type])
      file1 = Factory.insert(:file, intersection)
      params = Map.take(file0, [:path, :name])

      {:error, result} =  FileInternal.update(file1, params)
      assert :full_path in Keyword.keys(result.errors)
    end
  end

  describe "copy/3" do
    test "file is copied (same storage, different path)" do
      {file, %{server_id: server_id}} = SoftwareSetup.file()
      path = SoftwareHelper.random_file_path()

      storage = SoftwareHelper.get_storage(server_id)

      assert {:ok, new_file} = FileInternal.copy(file, storage, path)
      assert new_file.storage_id == file.storage_id
      assert new_file.software_type == file.software_type

      # TODO: Uncomment after fixing File model
      # assert new_file.type == file.type
      # assert new_file.file_modules == file.file_modules
    end

    test "refuses to copy file if it already exists (same path, storage)" do
      {file, %{server_id: server_id}} = SoftwareSetup.file()

      storage = SoftwareHelper.get_storage(server_id)

      assert {:error, result} = FileInternal.copy(file, storage, file.path)
      assert :full_path in Keyword.keys(result.errors)
    end

    test "file is copied (different storage)" do
      {file, _} = SoftwareSetup.file()
      {destination, _} = ServerSetup.server()

      storage = SoftwareHelper.get_storage(destination.server_id)

      assert {:ok, new_file} = FileInternal.copy(file, storage, file.path)

      assert new_file.name == file.name
      assert new_file.storage_id == storage.storage_id
      refute new_file.storage_id == file.storage_id
    end
  end

  describe "moving" do
    test "to another path" do
      file = Factory.insert(:file)
      path = Factory.build(:file).path

      {:ok, file} = FileInternal.move(file, path)

      assert path == file.path
    end

    test "fails on path identity conflict" do
      file0 = Factory.insert(:file)
      similarities = Map.take(file0, [:name, :storage, :software_type])
      file1 = Factory.insert(:file, similarities)

      {:error, result} = FileInternal.move(file1, file0.path)
      assert :full_path in Keyword.keys(result.errors)
    end
  end

  describe "renaming" do
    test "succeeds with a valid non-conflicting name" do
      file = Factory.insert(:file)
      name = Factory.params_for(:file).name

      {:ok, file} = FileInternal.rename(file, name)

      assert name == file.name
    end

    test "fails on path identity conflict" do
      file0 = Factory.insert(:file)
      similarities = Map.take(file0, [:path, :software_type, :storage])
      file1 = Factory.insert(:file, similarities)

      # FIXME: this is thanks to how ExMachina works
      file1 = Repo.update! File.update_changeset(file1, similarities)

      {:error, result} = FileInternal.rename(file1, file0.name)
      assert :full_path in Keyword.keys(result.errors)
    end
  end

  test "setting modules" do
    file = Factory.insert(:file)
    modules = generate_software_modules(file.software_type)

    {:ok, file2} = FileInternal.set_modules(file, modules)

    # created modules from `modules`
    assert FileInternal.get_modules(file2) == modules
  end

  describe "getting modules" do
    test "returns file modules as a map" do
      file = Factory.insert(:file)
      modules = generate_software_modules(file.software_type)

      FileInternal.set_modules(file, modules)

      file_modules = FileInternal.get_modules(file)
      assert modules == file_modules
    end
  end

  describe "delete/1" do
    test "removes entry" do
      file = Factory.insert(:file)

      assert Repo.get(File, file.file_id)

      FileInternal.delete(file)

      refute Repo.get(File, file.file_id)
    end
  end
end
