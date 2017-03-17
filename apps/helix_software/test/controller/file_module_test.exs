defmodule Helix.Software.Controller.FileModuleTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Software.Controller.FileModule, as: FileModuleController
  alias Helix.Software.Model.ModuleRole
  alias Helix.Software.Repo

  alias Helix.Software.Factory

  @moduletag :integration

  defp generate_module_roles(file_type) do
    file_type
    |> ModuleRole.Query.by_file_type()
    |> Repo.all()
    |> Enum.map(&({&1.module_role_id, Burette.Number.number(1..1024)}))
    |> :maps.from_list()
  end

  test "creating succeeds with valid params" do
    f = Factory.insert(:file)
    module_roles = generate_module_roles(f.file_type)

    assert {:ok, file_modules} = FileModuleController.create(f, module_roles)
    assert module_roles == file_modules
  end

  describe "getting" do
    test "returns file modules as a map" do
      file = Factory.insert(:file)
      module_roles = generate_module_roles(file.file_type)

      FileModuleController.create(file, module_roles)
      file_modules = FileModuleController.get_file_modules(file)

      assert module_roles == file_modules
    end

    test "returns empty map when nothing is found" do
      file = Factory.insert(:file)
      file_modules = FileModuleController.get_file_modules(file)

      assert Enum.empty?(file_modules)
    end
  end

  describe "updating" do
    test "succeeds with valid params" do
      file = Factory.insert(:file)
      module_roles = generate_module_roles(file.file_type)
      {:ok, file_modules} = FileModuleController.create(file, module_roles)

      version = Burette.Number.number(1..1024)
      module_id =
        file_modules
        |> Map.keys()
        |> Enum.random()

      {:ok, _} = FileModuleController.update(file, module_id, version)
      file_modules = FileModuleController.get_file_modules(file)

      assert version == file_modules[module_id]
    end

    test "fails when module doesn't exists" do
      file = Factory.insert(:file)
      module_id = Random.pk()
      version = Burette.Number.number(1..1024)

      assert {:error, :notfound} ==
        FileModuleController.update(file, module_id, version)
    end
  end

  test "deleting deletes every file modules" do
    file = Factory.insert(:file)
    module_roles = generate_module_roles(file.file_type)

    {:ok, _} = FileModuleController.create(file, module_roles)

    Repo.delete(file)

    file_modules = FileModuleController.get_file_modules(file)

    refute Enum.empty?(module_roles)
    assert Enum.empty?(file_modules)
  end
end