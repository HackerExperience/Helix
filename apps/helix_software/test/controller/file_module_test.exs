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

  test "file modules creation creates the correct roles" do
    file = Factory.insert(:file)
    module_roles = generate_module_roles(file.file_type)

    {:ok, file_modules1} = FileModuleController.create(file, module_roles)
    file_modules2 = FileModuleController.get_file_modules(file)

    # created roles from module_roles
    assert module_roles == file_modules1

    # roles found are the same as those yielded by create
    assert file_modules1 == file_modules2
  end

  describe "file modules fetching" do
    test "returns file modules as a map" do
      file = Factory.insert(:file)
      module_roles = generate_module_roles(file.file_type)
      FileModuleController.create(file, module_roles)

      file_modules = FileModuleController.get_file_modules(file)

      refute 0 == map_size(file_modules)
    end

    test "yields empty map when nothing is found" do
      file = Factory.insert(:file)
      file_modules = FileModuleController.get_file_modules(file)

      assert Enum.empty?(file_modules)
    end
  end

  describe "file modules updating" do
    test "updates module version" do
      file = Factory.insert(:file)
      module_roles = generate_module_roles(file.file_type)
      {:ok, file_modules} = FileModuleController.create(file, module_roles)

      module_id = file_modules |> Map.keys() |> Enum.random()

      version = Burette.Number.number(1..1024)
      {:ok, _} = FileModuleController.update(file, module_id, version)
      file_modules = FileModuleController.get_file_modules(file)

      assert version == file_modules[module_id]
    end

    test "fails when module doesn't exists" do
      file = Factory.insert(:file)
      module_id = Random.pk()
      version = Burette.Number.number(1..1024)

      assert {:error, :notfound} == FileModuleController.update(file, module_id, version)
    end
  end

  test "deleting a file deletes it's modules" do
    file = Factory.insert(:file)
    module_roles = generate_module_roles(file.file_type)
    {:ok, _} = FileModuleController.create(file, module_roles)

    file_modules1 = FileModuleController.get_file_modules(file)

    Repo.delete(file)

    file_modules2 = FileModuleController.get_file_modules(file)

    refute Enum.empty?(file_modules1)
    assert Enum.empty?(file_modules2)
  end
end