defmodule Helix.Software.Controller.FileModuleTest do

  use ExUnit.Case, async: true

  alias HELL.TestHelper.Random
  alias Helix.Software.Controller.FileModule, as: FileModuleController
  alias Helix.Software.Model.SoftwareModule
  alias Helix.Software.Repo

  alias Helix.Software.Factory

  @moduletag :integration

  defp generate_software_modules(software_type) do
    software_type
    |> SoftwareModule.Query.by_software_type()
    |> Repo.all()
    |> Enum.map(fn module ->
      %{
        software_module: module.software_module,
        module_version: Burette.Number.number(1..1024)
      }
    end)
  end

  test "creation creates the correct modules" do
    file = Factory.insert(:file)
    software_modules = generate_software_modules(file.software_type)

    {:ok, file_modules} = FileModuleController.create(file, software_modules)

    file_modules =
      Enum.map(file_modules, fn module ->
        %{
          software_module: module.software_module,
          module_version: module.module_version
        }
      end)

    # created modules from software_modules
    assert software_modules == file_modules
  end

  describe "getting" do
    test "returns file modules as a map" do
      file = Factory.insert(:file)
      software_modules = generate_software_modules(file.software_type)

      expected =
        software_modules
        |> Enum.map(&{&1.software_module, &1.module_version})
        |> :maps.from_list()

      FileModuleController.create(file, software_modules)

      assert expected == FileModuleController.get_file_modules(file)
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
      software_module = generate_software_modules(file.software_type)
      {:ok, file_modules} = FileModuleController.create(file, software_module)

      version = Burette.Number.number(1..1024)
      %{software_module: module} = Enum.random(file_modules)

      {:ok, _} = FileModuleController.update(file, module, version)
      file_modules = FileModuleController.get_file_modules(file)

      assert version == file_modules[module]
    end

    test "fails when module doesn't exists" do
      file = Factory.insert(:file)
      software_module = Random.string()
      version = Burette.Number.number(1..1024)

      result = FileModuleController.update(file, software_module, version)
      assert {:error, :notfound} == result
    end
  end

  test "deleting deletes every file modules" do
    file = Factory.insert(:file)
    software_module = generate_software_modules(file.software_type)

    {:ok, _} = FileModuleController.create(file, software_module)

    Repo.delete(file)

    file_modules = FileModuleController.get_file_modules(file)
    assert Enum.empty?(file_modules)
  end
end
