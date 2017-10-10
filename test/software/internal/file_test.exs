defmodule Helix.Software.Internal.FileTest do

  use Helix.Test.Case.Integration

  alias Helix.Software.Internal.File, as: FileInternal
  alias Helix.Software.Model.File

  alias HELL.TestHelper.Random
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Software.Helper, as: SoftwareHelper
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  describe "create/2" do
    test "creates file and modules" do
      {params, modules} = generate_params()

      # Inserts the file
      assert {:ok, file} = FileInternal.create(params, modules)

      # Fetch from database
      entry = FileInternal.fetch(file.file_id)

      # File has been inserted with the expected data
      assert entry
      assert entry.storage_id == params.storage_id
      assert entry.name == params.name
      assert entry.software_type == params.software_type

      # Modules are valid too
      assert entry.modules

      # They were created with the expected data and are `format/1`-ed
      Enum.each(modules, fn {module, data} ->
        assert entry_module = Map.fetch!(entry.modules, module)
        assert entry_module.version == data.version
      end)
    end

    test "fails when file path conflicts with another one" do
      {params, modules} = generate_params()

      assert {:ok, _file1} = FileInternal.create(params, modules)

      assert {:error, result} = FileInternal.create(params, modules)
      assert :full_path in Keyword.keys(result.errors)
    end

    # TODO: Wait for SoftwareType refactor
    @tag :pending
    test "fails if passed modules are invalid" do
      {params, _} = generate_params(:cracker)
      {_, bad_modules} = generate_params(:hasher)

      assert {:error, _changeset} = FileInternal.create(params, bad_modules)
    end

    # TODO: Wait for issue #279
    @tag :pending
    test "fails if there's no space left on device"

    defp generate_params(software_type \\ :cracker) do
      {storage, _} = SoftwareSetup.storage()

      params = %{
        name: SoftwareHelper.random_file_name(),
        path: SoftwareHelper.random_file_path(),
        software_type: software_type,
        storage_id: storage.storage_id,
        file_size: SoftwareHelper.random_file_size()
      }

      modules = SoftwareHelper.get_modules(software_type)

      {params, modules}
    end
  end

  describe "fetch/1" do
    test "returns a valid and formatted entry" do
      {file, _} = SoftwareSetup.file()

      assert entry = FileInternal.fetch(file.file_id)

      assert entry.file_id == file.file_id
      assert entry.name == file.name
      assert entry.path == file.path

      # Modules were formatted:

      # They are now a map
      refute is_list(entry.modules)
      assert is_map(entry.modules)

      # And they are exactly the same from the original file
      Enum.each(file.modules, fn {module_name, data} ->
        assert Map.has_key?(entry.modules, module_name)
        assert entry.modules[module_name].version == data.version
      end)
    end

    test "returns nil if file doesn't exist" do
      refute FileInternal.fetch(File.ID.generate())
    end
  end

  describe "fetch_best/2" do
    test "selects the best file" do
      {storage, _} = SoftwareSetup.storage()

      best_crc_module =
        SoftwareHelper.generate_module(
          :cracker,
          %{bruteforce: 500, overflow: 1}
        )

      worst_crc_module =
        SoftwareHelper.generate_module(
          :cracker,
          %{bruteforce: 1, overflow: 500}
        )

      mid_crc_1_module =
        SoftwareHelper.generate_module(
          :cracker,
          %{bruteforce: 400, overflow: 200}
        )

      mid_crc_2_module =
        SoftwareHelper.generate_module(
          :cracker,
          %{bruteforce: 200, overflow: 400}
        )

      best_fwl_module =
        SoftwareHelper.generate_module(
          :firewall,
          %{fwl_active: 200, fwl_passive: 100}
        )

      worst_fwl_module =
        SoftwareHelper.generate_module(
          :firewall,
          %{fwl_active: 100, fwl_passive: 200}
        )

      best_crc = add_file(storage, :cracker, best_crc_module)
      worst_crc = add_file(storage, :cracker, worst_crc_module)
      _mid_crc_1 = add_file(storage, :cracker, mid_crc_1_module)
      _mid_crc_2 = add_file(storage, :cracker, mid_crc_2_module)
      best_fwl = add_file(storage, :firewall, best_fwl_module)
      worst_fwl = add_file(storage, :firewall, worst_fwl_module)

      crc = FileInternal.fetch_best(storage, :bruteforce)
      assert crc == best_crc

      fwl = FileInternal.fetch_best(storage, :fwl_active)
      assert fwl == best_fwl

      # Now looking for the opposite modules, which we are calling `worst`
      crc = FileInternal.fetch_best(storage, :overflow)
      assert crc == worst_crc

      fwl = FileInternal.fetch_best(storage, :fwl_passive)
      assert fwl == worst_fwl
    end

    defp add_file(storage, type, modules) do
      SoftwareSetup.file!(
        storage_id: storage.storage_id,
        type: type,
        modules: modules
      )
    end
  end

  describe "get_files_on_storage/1" do
    test "returns non-encrypted files" do
      {storage, _} = SoftwareSetup.storage()

      # Add 3 files into the storage
      file_opts = [storage_id: storage.storage_id]
      SoftwareSetup.random_files!(file_opts: file_opts, total: 3)

      files = FileInternal.get_files_on_storage(storage)

      # All 3 unencrypted files have been fetched
      assert 3 == Enum.count(files)
      assert Enum.all?(files, &(is_nil(&1.crypto_version)))
    end

    test "returns encrypted files" do
      {storage, _} = SoftwareSetup.storage()

      # Add 3 encrypted files into the storage
      file_opts = [
          storage_id: storage.storage_id,
          crypto_version: Random.number(min: 1, max: 100)
        ]
      SoftwareSetup.random_files!(file_opts: file_opts, total: 3)

      files = FileInternal.get_files_on_storage(storage)

      # All 3 encrypted files were fetched
      assert 3 == Enum.count(files)
      assert Enum.all?(files, &(not is_nil(&1.crypto_version)))
    end
  end

  describe "copy/3" do
    test "file is copied (same storage, different path)" do
      {file, %{server_id: server_id}} = SoftwareSetup.file()

      storage = SoftwareHelper.get_storage(server_id)

      params = %{
        path: SoftwareHelper.random_file_path(),
        name: SoftwareHelper.random_file_name()
      }

      # New file was created
      assert {:ok, new_file} = FileInternal.copy(file, storage, params)
      assert new_file.storage_id == file.storage_id
      assert new_file.software_type == file.software_type

      # Modules were copied correctly
      assert new_file.type == file.type
      assert new_file.modules == file.modules

      # Source file hasn't changed in any way
      assert FileInternal.fetch(file.file_id) == file
    end

    test "refuses to copy file if it already exists (same path, storage)" do
      {file, %{server_id: server_id}} = SoftwareSetup.file()

      storage = SoftwareHelper.get_storage(server_id)

      params = %{
        name: file.name,
        path: file.path
      }

      assert {:error, result} = FileInternal.copy(file, storage, params)
      assert :full_path in Keyword.keys(result.errors)
    end

    test "allows the file to be copied to the same path, different name" do
      {file, %{server_id: server_id}} = SoftwareSetup.file()

      storage = SoftwareHelper.get_storage(server_id)

      params = %{
        name: SoftwareHelper.random_file_name,
        path: file.path
      }

      assert {:ok, _} = FileInternal.copy(file, storage, params)
    end

    test "file is copied (different storage)" do
      {file, _} = SoftwareSetup.file()
      {destination, _} = ServerSetup.server()

      storage = SoftwareHelper.get_storage(destination.server_id)

      params = %{
        name: file.name,
        path: file.path
      }

      assert {:ok, new_file} = FileInternal.copy(file, storage, params)

      assert new_file.name == file.name
      assert new_file.storage_id == storage.storage_id
      refute new_file.storage_id == file.storage_id

      # Original file wasn't modified
      assert FileInternal.fetch(file.file_id) == file
    end
  end

  describe "rename/2" do
    test "renames the file" do
      {file, _} = SoftwareSetup.file()

      new_name = SoftwareHelper.random_file_name()

      # File has been successfully renamed
      assert {:ok, new_file} = FileInternal.rename(file, new_name)
      assert new_file.file_id == file.file_id
      assert new_file.name == new_name
    end

    test "fails if new name generates a path conflict" do
      {file1, %{storage_id: storage_id}} = SoftwareSetup.file()

      storage = SoftwareHelper.get_storage(storage_id)

      params = %{
        name: SoftwareHelper.random_file_name(),
        path: file1.path
      }

      # Context: `file1` and `file2` exist on the same directory, but they have
      # different names. We'll rename `file1` to the same name of `file2`, which
      # should generate a conflict
      {:ok, file2} = FileInternal.copy(file1, storage, params)

      assert {:error, result} = FileInternal.rename(file1, file2.name)
      assert :full_path in Keyword.keys(result.errors)
    end
  end

  describe "move/2" do
    test "file is moved to a different path" do
      {file, _} = SoftwareSetup.file()

      new_path = SoftwareHelper.random_file_path()

      # File has been successfully moved
      assert {:ok, new_file} = FileInternal.move(file, new_path)
      assert new_file.file_id == file.file_id
      assert new_file.path == SoftwareHelper.format_path(new_path)
    end

    test "fails to move if there's a conflict on the new path" do
      {file1, %{storage_id: storage_id}} = SoftwareSetup.file()

      storage = SoftwareHelper.get_storage(storage_id)

      params = %{
        name: file1.name,
        path: SoftwareHelper.random_file_path()
      }

      # Context: `file1` and `file2` have the same name, live on the same
      # storage but have different paths.
      # We'll move `file1` into the same path of `file2`, which should generate
      # a conflict.
      {:ok, file2} = FileInternal.copy(file1, storage, params)

      assert {:error, result} = FileInternal.move(file1, file2.path)
      assert :full_path in Keyword.keys(result.errors)
    end
  end

  describe "delete/1" do
    test "removes entry" do
      {file, _} = SoftwareSetup.file()

      assert FileInternal.fetch(file.file_id)

      FileInternal.delete(file)

      refute FileInternal.fetch(file.file_id)
    end
  end
end
