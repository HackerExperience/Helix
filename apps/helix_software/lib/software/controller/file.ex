defmodule Helix.Software.Controller.File do

  alias Helix.Software.Controller.CryptoKey
  alias Helix.Software.Model.File
  alias Helix.Software.Model.FileModule
  alias Helix.Software.Model.Storage
  alias Helix.Software.Repo

  import Ecto.Query, only: [where: 3, select: 3]

  @spec create(File.creation_params) ::
    {:ok, File.t}
    | {:error, :file_exists | Ecto.Changeset.t}
  def create(params) do
    params
    |> File.create_changeset()
    |> Repo.insert()
    |> parse_errors()
  end

  @spec fetch(HELL.PK.t) :: File.t | nil
  def fetch(file_id),
    do: Repo.get(File, file_id)

  @spec get_files_on_target_storage(Storage.t, Storage.t) :: [File.t]
  @doc """
  Gets all files on `target_storage` that are not encrypted or for whom is there
  a key on `origin_storage`
  """
  def get_files_on_target_storage(origin_storage, target_storage) do
    keyed_files = CryptoKey.get_files_targeted_on_storage(
      origin_storage,
      target_storage)

    target_storage
    |> File.Query.from_storage()
    |> File.Query.not_encrypted()
    |> File.Query.from_id_list(keyed_files, :or)
    |> Repo.all()
  end

  @spec update(File.t, File.update_params) ::
    {:ok, File.t}
    | {:error, :file_exists | Ecto.Changeset.t}
  def update(file, params) do
    file
    |> File.update_changeset(params)
    |> Repo.update()
    |> parse_errors()
  end

  @spec copy(File.t, path :: String.t, storage_id :: HELL.PK.t) ::
    {:ok, File.t}
    | {:error, :file_exists | Ecto.Changeset.t}
  def copy(file, path, storage_id) do
    # TODO: allow copying to the same folder
    params = %{
      name: file.name,
      path: path,
      file_size: file.file_size,
      software_type: file.software_type,
      storage_id: storage_id}
    create(params)
  end

  @spec move(File.t, path :: String.t) ::
    {:ok, File.t}
    | {:error, :file_exists | Ecto.Changeset.t}
  def move(file, path) do
    file
    |> File.update_changeset(%{path: path})
    |> Repo.update()
    |> parse_errors()
  end

  @spec rename(File.t, String.t) ::
    {:ok, File.t}
    | {:error, :file_exists | Ecto.Changeset.t}
  def rename(file, file_name) do
    params = %{name: file_name}
    file
    |> File.update_changeset(params)
    |> Repo.update()
    |> parse_errors()
  end

  @spec delete(File.t) :: no_return
  def delete(file = %File{}),
    do: delete(file.file_id)

  @spec delete(File.id) :: no_return
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

  @spec get_modules(File.t) :: File.modules
  def get_modules(file) do
    file
    |> FileModule.Query.from_file()
    |> select([fm], {fm.software_module, fm.module_version})
    |> Repo.all()
    |> :maps.from_list()
  end

  @spec parse_errors({:ok | :error, Ecto.Changeset.t}) ::
    {:ok, Ecto.Changeset.t}
    | {:error, :file_exists | Ecto.Changeset.t}
  defp parse_errors({:ok, changeset}),
    do: {:ok, changeset}
  defp parse_errors({:error, changeset}) do
    if Keyword.get(changeset.errors, :full_path) do
      {:error, :file_exists}
    else
      {:error, changeset}
    end
  end
end
