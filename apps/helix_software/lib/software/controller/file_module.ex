defmodule Helix.Software.Controller.FileModule do

  alias Helix.Software.Model.File
  alias Helix.Software.Model.FileModule
  alias Helix.Software.Repo

  import Ecto.Query, only: [select: 3]

  @type software_modules :: %{modules :: HELL.PK.t => version :: pos_integer}

  @spec create(File.t, software_modules) ::
    {:ok, software_modules}
    | {:error, :internal}
  def create(file, modules) do
    r = Enum.map(modules, fn {module, v} ->
      p = %{
        file_id: file.file_id,
        software_module: module,
        module_version: v
      }

      FileModule.create_changeset(p)
    end)

    Repo.transaction(fn ->
      if Enum.all?(r, &match?({:ok, _}, Repo.insert(&1))) do
        modules
      else
        Repo.rollback(:internal)
      end
    end)
  end

  @spec get_file_modules(File.t) :: software_modules
  def get_file_modules(file) do
    file
    |> FileModule.Query.from_file()
    |> select([m], {m.software_module, m.module_version})
    |> Repo.all()
    |> :maps.from_list()
  end

  # REVIEW: on sucess return only :ok or {:ok, version}. I don't really see the
  #   point in returning the FileModule struct as it's not even used for
  #   anything
  @spec update(File.t, HELL.PK.t, version :: pos_integer) ::
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