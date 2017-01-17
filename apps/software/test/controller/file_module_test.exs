defmodule Helix.Software.Controller.FileModuleTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Software.Controller.File, as: FileController
  alias Helix.Software.Controller.FileModule, as: FileModuleController
  alias Helix.Software.Controller.Storage, as: StorageController
  alias Helix.Software.Model.FileType
  alias Helix.Software.Model.ModuleRole
  alias Helix.Software.Repo

  defp create_file_type() do
    file_type =
      %{
        file_type: Random.string(min: 20),
        extension: Random.string(min: 3, max: 3)}
      |> FileType.create_changeset()
      |> Repo.insert!()
    file_type.file_type
  end

  defp create_module_roles(file_type) do
    Enum.each(0..Random.number(min: 3, max: 20), fn _ ->
      %{
        module_role: Random.string(min: 20),
        file_type: file_type}
      |> ModuleRole.create_changeset()
      |> Repo.insert!()
    end)
  end

  defp generate_module_roles(file_type) do
    file_type
    |> ModuleRole.Query.by_file_type()
    |> Repo.all()
    |> Enum.map(&({&1.module_role_id, Random.number(min: 1, max: 8000)}))
    |> Enum.into(%{})
  end

  defp create_file(file_type, storage_id) do
    params = %{
      name: Random.string(min: 20),
      file_path: Random.digits(min: 20),
      file_type: file_type,
      file_size: Random.number(min: 1),
      storage_id: storage_id
    }
    {:ok, file} = FileController.create(params)
    file
  end

  setup_all do
    {:ok, storage} = StorageController.create()

    file_type = create_file_type()
    create_module_roles(file_type)

    {:ok, file_type: file_type, storage_id: storage.storage_id}
  end

  test "file modules creation creates the correct roles", context do
    file = create_file(context.file_type, context.storage_id)
    module_roles = generate_module_roles(context.file_type)

    {:ok, file_modules1} = FileModuleController.create(file, module_roles)
    file_modules2 = FileModuleController.find(file)

    # created roles from module_roles
    assert module_roles == file_modules1

    # roles found are the same as those yielded by create
    assert file_modules1 == file_modules2
  end

  describe "file modules fetching" do
    test "fetches existing file modules", context do
      file = create_file(context.file_type, context.storage_id)
      module_roles = generate_module_roles(context.file_type)

      {:ok, file_modules1} = FileModuleController.create(file, module_roles)
      file_modules2 = FileModuleController.find(file)

      # fetched a non empty map
      refute 0 === map_size(file_modules2)

      # fetched the same data yielded by create
      assert file_modules1 == file_modules2
    end

    test "yields empty map when nothing is found", context do
      file = create_file(context.file_type, context.storage_id)
      file_modules = FileModuleController.find(file)

      # nothing could be fetched
      assert 0 === map_size(file_modules)
    end
  end

  describe "file modules updating" do
    test "updates module version", context do
      file = create_file(context.file_type, context.storage_id)
      module_roles = generate_module_roles(context.file_type)
      {:ok, file_modules} = FileModuleController.create(file, module_roles)

      module_id =
        file_modules
        |> Map.keys()
        |> Enum.random()

      version = Random.number(min: 1, max: 8000)
      {:ok, file_module} = FileModuleController.update(file, module_id, version)
      file_modules = FileModuleController.find(file)

      # version yielded by update is the same obtained from find
      assert file_module.module_version == file_modules[module_id]

      # module version was changed to the expected value
      assert version == file_module.module_version
    end

    test "file module not found", context do
      file = create_file(context.file_type, context.storage_id)
      module_id = HELL.PK.generate([])
      version = Random.number(min: 1, max: 8000)

      # got expected error
      assert {:error, :notfound} ==
        FileModuleController.update(file, module_id, version)
    end
  end

  test "deleting a file deletes it's modules", context do
    file = create_file(context.file_type, context.storage_id)
    module_roles = generate_module_roles(context.file_type)
    {:ok, _} = FileModuleController.create(file, module_roles)

    file_modules1 = FileModuleController.find(file)

    Repo.delete(file)

    file_modules2 = FileModuleController.find(file)

    # modules exist before deleting the file
    refute 0 === map_size(file_modules1)

    # no modules are found after deleting the file
    assert 0 === map_size(file_modules2)
  end
end