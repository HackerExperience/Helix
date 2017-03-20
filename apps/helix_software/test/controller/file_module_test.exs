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
    |> Enum.map(&({&1.software_module, Burette.Number.number(1..1024)}))
    |> :maps.from_list()
  end

  test "creating succeeds with valid params" do
    f = Factory.insert(:file)
    software_modules = generate_software_modules(f.software_type)

    assert {:ok, file_modules} = FileModuleController.create(f, software_modules)
    assert software_modules == file_modules
  end

  describe "getting" do
    test "returns file modules as a map" do
      file = Factory.insert(:file)
      software_modules = generate_software_modules(file.software_type)

      FileModuleController.create(file, software_modules)
      file_modules = FileModuleController.get_file_modules(file)

      assert software_modules == file_modules
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
      software_modules = generate_software_modules(file.software_type)
      {:ok, file_modules} = FileModuleController.create(file, software_modules)

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
      result = FileModuleController.update(file, module_id, version)

      assert {:error, :notfound} == result
    end
  end

  test "deleting deletes every file modules" do
    file = Factory.insert(:file)
    software_modules = generate_software_modules(file.software_type)

    {:ok, _} = FileModuleController.create(file, software_modules)
    Repo.delete(file)
    file_modules = FileModuleController.get_file_modules(file)

    assert Enum.empty?(file_modules)
  end
end
