defmodule Helix.Software.Internal.File do

  import Ecto.Query, only: [where: 3, select: 3]

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

  @spec get_files_on_target_storage(Storage.t) ::
    [File.t]
  @doc """
  Gets all files on `target_storage`
  """
  def get_files_on_target_storage(target_storage) do
    target_storage
    |> File.Query.from_storage()
    |> Repo.all()
  end

  @spec update(File.t, File.update_params) ::
    {:ok, File.t}
    | {:error, Ecto.Changeset.t}
  def update(file, params) do
    file
    |> File.update_changeset(params)
    |> Repo.update()
  end

  @spec copy(File.t, Storage.t, path :: String.t) ::
    {:ok, File.t}
    | {:error, Ecto.Changeset.t}
  def copy(file, storage, path) do
    # TODO: allow copying to the same folder
    file
    |> File.copy(storage, %{path: path})
    |> Repo.insert()
  end

  @spec move(File.t, path :: String.t) ::
    {:ok, File.t}
    | {:error, Ecto.Changeset.t}
  def move(file, path) do
    file
    |> File.update_changeset(%{path: path})
    |> Repo.update()
  end

  @spec rename(File.t, String.t) ::
    {:ok, File.t}
    | {:error, Ecto.Changeset.t}
  def rename(file, file_name) do
    params = %{name: file_name}
    file
    |> File.update_changeset(params)
    |> Repo.update()
  end

  @spec encrypt(File.t, pos_integer) ::
    {:ok, Ecto.Changeset.t}
    | {:error, Ecto.Changeset.t}
  def encrypt(file = %File{}, version) when version >= 1 do
    file
    |> File.update_changeset(%{crypto_version: version})
    |> Repo.update()
  end

  @spec decrypt(File.t) ::
    {:ok, Ecto.Changeset.t}
    | {:error, Ecto.Changeset.t}
  def decrypt(file = %File{}) do
    file
    |> File.update_changeset(%{crypto_version: nil})
    |> Repo.update()
  end

  @spec delete(File.t | File.id) ::
    :ok
  def delete(file = %File{}),
    do: delete(file.file_id)
  def delete(file_id) do
    File
    |> where([f], f.file_id == ^file_id)
    |> Repo.delete_all()

    :ok
  end

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

  @spec get_modules(File.t) ::
    File.modules
  def get_modules(file) do
    file
    |> FileModule.Query.from_file()
    |> select([fm], {fm.software_module, fm.module_version})
    |> Repo.all()
    |> :maps.from_list()
  end
end
