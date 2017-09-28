defmodule Helix.Software.Internal.File do

  import Ecto.Query, only: [select: 3]

  alias Helix.Software.Model.File
  alias Helix.Software.Model.FileModule
  alias Helix.Software.Model.Storage
  alias Helix.Software.Repo

  @spec create(File.creation_params) ::
    {:ok, File.t}
    | {:error, Ecto.Changeset.t}
  def create(params) do
    params
    |> File.create_changeset()
    |> Repo.insert()
  end

  @spec fetch(File.id) ::
    File.t
    | nil
  def fetch(file_id),
    do: Repo.get(File, file_id)

  @spec get_files_on_target_storage(Storage.idt) ::
    [File.t]
  @doc """
  Gets all files on `target_storage`
  """
  def get_files_on_target_storage(target_storage) do
    target_storage
    |> File.Query.by_storage()
    |> Repo.all()
  end

  @spec update(File.t, File.update_params) ::
    {:ok, File.t}
    | {:error, File.changeset}
  def update(file, params) do
    file
    |> File.update_changeset(params)
    |> Repo.update()
  end

  @spec copy(File.t, Storage.t, File.path) ::
    {:ok, File.t}
    | {:error, File.changeset}
  def copy(file, storage, path) do
    # TODO: allow copying to the same folder
    # TODO: Check storage requirements
    file
    |> File.copy(storage, %{path: path})
    |> Repo.insert()
  end

  @spec move(File.t, File.path) ::
    {:ok, File.t}
    | {:error, File.changeset}
  def move(file, path) do
    file
    |> File.update_changeset(%{path: path})
    |> Repo.update()
  end

  @spec rename(File.t, File.name) ::
    {:ok, File.t}
    | {:error, File.changeset}
  def rename(file, file_name) do
    params = %{name: file_name}
    file
    |> File.update_changeset(params)
    |> Repo.update()
  end

  @spec encrypt(File.t, File.module_version) ::
    {:ok, File.changeset}
    | {:error, File.changeset}
  def encrypt(file = %File{}, version) when version >= 1 do
    file
    |> File.update_changeset(%{crypto_version: version})
    |> Repo.update()
  end

  @spec decrypt(File.t) ::
    {:ok, File.changeset}
    | {:error, File.changeset}
  def decrypt(file = %File{}) do
    file
    |> File.update_changeset(%{crypto_version: nil})
    |> Repo.update()
  end

  @spec delete(File.t) ::
    :ok
  def delete(file) do
    Repo.delete(file)

    :ok
  end

  # TODO: Merge create + set_modules. Should be always called together.
  @spec set_modules(File.t, File.modules) ::
    {:ok, File.t}
    | {:error, File.changeset}
  def set_modules(file, modules) do
    changeset =
      file
      |> Repo.preload(:file_modules)
      |> File.set_modules(modules)

    Repo.update(changeset)
  end

  @spec get_modules(File.t) ::
    File.modules
  def get_modules(file) do
    file
    |> FileModule.Query.by_file()
    |> select([fm], {fm.software_module, fm.module_version})
    |> Repo.all()
    |> :maps.from_list()
  end

  def load_modules(file),
    do: %{file| file_modules: get_modules(file)}
end
