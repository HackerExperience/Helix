defmodule Helix.Software.Controller.ModuleTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random, as: Random
  alias Helix.Software.Controller.File, as: FileController
  alias Helix.Software.Controller.Module, as: ModuleController
  alias Helix.Software.Controller.Storage, as: StorageController
  alias Helix.Software.Model.FileType
  alias Helix.Software.Model.ModuleRole
  alias Helix.Software.Repo

  defp create_file(file_type, storage_id) do
    params = %{
      name: Random.string(min: 20),
      file_path: "dev.null",
      file_type: file_type,
      file_size: Random.number(min: 1),
      storage_id: storage_id
    }
    {:ok, file} = FileController.create(params)
    file
  end

  defp generate_module_roles(file_type) do
    file_type
    |> ModuleRole.Query.by_type()
    |> Repo.all()
    |> Enum.shuffle()
    |> Enum.take(Random.number(min: 1, max: 8))
    |> Enum.map(&({&1.module_role_id, Random.number(min: 1, max: 8000)}))
    |> Enum.into(%{})
  end

  setup_all do
    file_type =
      FileType
      |> Repo.all()
      |> Enum.reject(fn file_type ->
        roles =
          file_type.file_type
          |> ModuleRole.Query.by_type()
          |> Repo.all()

        length(roles) < 3
      end)
      |> Enum.random()
      |> Map.fetch!(:file_type)

    {:ok, storage} = StorageController.create()
    {:ok, file_type: file_type, storage_id: storage.storage_id}
  end

  test "file modules creation creates the correct roles", context do
    file = create_file(context.file_type, context.storage_id)
    module_roles = generate_module_roles(context.file_type)

    {:ok, file_modules1} = ModuleController.create(file, module_roles)
    file_modules2 = ModuleController.find(file)

    # created roles from module_roles
    assert module_roles == file_modules1

    # roles found are the same as those yielded by create
    assert file_modules1 == file_modules2
  end

  describe "file modules fetching" do
    test "fetches existing file modules", context do
      file = create_file(context.file_type, context.storage_id)
      module_roles = generate_module_roles(context.file_type)

      {:ok, file_modules1} = ModuleController.create(file, module_roles)
      file_modules2 = ModuleController.find(file)

      # fetched a non empty list
      refute Enum.empty?(file_modules2)

      # fetched the same data yielded by create
      assert file_modules1 == file_modules2
    end

    test "yields empty list when nothing is found", context do
      file = create_file(context.file_type, context.storage_id)
      file_modules = ModuleController.find(file)

      # nothing could be fetched
      assert Enum.empty?(file_modules)
    end
  end

  describe "file modules updating" do
    test "updates module version", context do
      file = create_file(context.file_type, context.storage_id)
      module_roles = generate_module_roles(context.file_type)
      {:ok, file_modules} = ModuleController.create(file, module_roles)

      module_id =
        file_modules
        |> Map.keys()
        |> Enum.random()

      version = Random.number(min: 1, max: 8000)
      {:ok, file_module} = ModuleController.update(file, module_id, version)
      file_modules = ModuleController.find(file)

      # version yielded by update is the same obtained from find
      assert file_module.module_version == file_modules[module_id]

      # module version was changed to the expected value
      assert version == file_module.module_version
    end

    test "module not found", context do
      file = create_file(context.file_type, context.storage_id)
      module_id = HELL.PK.generate([])
      version = Random.number(min: 1, max: 8000)

      # got expected error
      assert {:error, :notfound} ==
        ModuleController.update(file, module_id, version)
    end
  end
end