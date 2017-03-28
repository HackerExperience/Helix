defmodule Helix.Software.Controller.FileModuleTest do

  use ExUnit.Case, async: true

  alias Helix.Software.Controller.FileModule, as: FileModuleController
  alias Helix.Software.Model.SoftwareModule
  alias Helix.Software.Repo

  alias Helix.Software.Factory

  import Ecto.Query, only: [select: 3]

  @moduletag :integration

  defp generate_software_modules(software_type) do
    software_type
    |> SoftwareModule.Query.by_software_type()
    |> select([sm], sm.software_module)
    |> Repo.all()
    |> Enum.map(&{&1, Burette.Number.number(1..1024)})
    |> :maps.from_list()
  end

  test "creation creates the correct modules" do
    file = Factory.insert(:file)
    modules = generate_software_modules(file.software_type)

    {:ok, file_modules} = FileModuleController.set_modules(file, modules)

    # created modules from `modules`
    assert modules == file_modules
  end

  describe "getting" do
    test "returns file modules as a map" do
      file = Factory.insert(:file)
      modules = generate_software_modules(file.software_type)

      FileModuleController.set_modules(file, modules)

      file_modules = FileModuleController.get_file_modules(file)
      assert modules == file_modules
    end

    test "returns empty map when nothing is found" do
      file = Factory.insert(:file)
      file_modules = FileModuleController.get_file_modules(file)

      assert Enum.empty?(file_modules)
    end
  end

  test "deleting deletes every file modules" do
    file = Factory.insert(:file)
    software_module = generate_software_modules(file.software_type)

    {:ok, _} = FileModuleController.set_modules(file, software_module)

    Repo.delete(file)

    file_modules = FileModuleController.get_file_modules(file)
    assert Enum.empty?(file_modules)
  end
end
