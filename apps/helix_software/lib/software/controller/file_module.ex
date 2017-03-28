defmodule Helix.Software.Controller.FileModule do

  alias Helix.Software.Model.File
  alias Helix.Software.Model.FileModule
  alias Helix.Software.Repo

  import Ecto.Query, only: [select: 3]

  @spec set_modules(File.t, File.modules) ::
    {:ok, File.modules}
    | {:error, reason :: term}
  def set_modules(file, modules) do
    changeset =
      file
      |> Repo.preload(:file_modules)
      |> File.set_modules(modules)

    case Repo.update(changeset) do
      {:ok, file} ->
        modules =
          file.file_modules
          |> Enum.map(&{&1.software_module, &1.module_version})
          |> :maps.from_list()

        {:ok, modules}
      error ->
        error
    end
  end

  @spec get_file_modules(File.t) :: File.modules
  def get_file_modules(file) do
    file
    |> FileModule.Query.from_file()
    |> select([fm], {fm.software_module, fm.module_version})
    |> Repo.all()
    |> :maps.from_list()
  end
end
