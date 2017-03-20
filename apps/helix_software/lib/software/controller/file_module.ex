defmodule Helix.Software.Controller.FileModule do

  alias Helix.Software.Model.File
  alias Helix.Software.Model.FileModule
  alias Helix.Software.Repo

  import Ecto.Query, only: [select: 3]

  @type software_modules :: %{
    software_module :: String.t => version :: pos_integer
  }

  @spec create(File.t,
    [%{software_module: String.t,
    module_version: pos_integer}]) ::
      {:ok, [FileModule.t]}
      | {:error, :internal}
  def create(file, modules) do
    result =
      file
      |> Repo.preload(:file_modules)
      |> File.create_modules(modules)
      |> Repo.update()

    case result do
      {:ok, file} ->
        {:ok, file.file_modules}
      error ->
        error
    end
  end

  @spec get_file_modules(File.t) :: software_modules
  def get_file_modules(file) do
    file
    |> FileModule.Query.from_file()
    |> select([fm], {fm.software_module, fm.module_version})
    |> Repo.all()
    |> :maps.from_list()
  end

  # REVIEW: on sucess return only :ok or {:ok, version}. I don't really see the
  #   point in returning the FileModule struct as it's not even used for
  #   anything
  @spec update(File.t, String.t, version :: pos_integer) ::
    {:ok, FileModule.t}
    | {:error, :notfound | Ecto.Changeset.t}
  def update(file, software_module, version) do
    file_module =
      file
      |> FileModule.Query.from_file()
      |> FileModule.Query.by_software_module(software_module)
      |> Repo.one()

    if file_module do
      file_module
      |> FileModule.update_changeset(%{module_version: version})
      |> Repo.update()
    else
      {:error, :notfound}
    end
  end
end
