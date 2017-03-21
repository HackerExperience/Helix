defmodule Helix.Software.Controller.File do

  alias Helix.Software.Model.File
  alias Helix.Software.Repo

  import Ecto.Query, only: [where: 3]

  @spec create(File.creation_params) ::
    {:ok, File.t}
    | {:error, :file_exists | Ecto.Changeset.t}
  def create(params) do
    params
    |> File.create_changeset()
    |> Repo.insert()
    |> parse_errors()
  end

  @spec find(HELL.PK.t) :: {:ok, File.t} | {:error, :notfound}
  def find(file_id) do
    case Repo.get_by(File, file_id: file_id) do
      nil ->
        {:error, :notfound}
      file ->
        {:ok, file}
    end
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

  @spec copy(FileModel.t, file_path :: String.t, storage_id :: HELL.PK.t) ::
    {:ok, File.t}
    | {:error, :file_exists | Ecto.Changeset.t}
  def copy(file, file_path, storage_id) do
    # TODO: allow copying to the same folder
    params = %{
      name: file.name,
      file_path: file_path,
      file_size: file.file_size,
      file_type: file.file_type,
      storage_id: storage_id}
    create(params)
  end

  @spec move(File.t, file_path :: String.t, storage_id :: HELL.PK.t) ::
    {:ok, File.t}
    | {:error, :file_exists | Ecto.Changeset.t}
  def move(file, file_path, storage_id) do
    params = %{file_path: file_path, storage_id: storage_id}
    file
    |> File.update_changeset(params)
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

  @spec delete(HELL.PK.t) :: no_return
  def delete(file_id) do
    File
    |> where([f], f.file_id == ^file_id)
    |> Repo.delete_all()

    :ok
  end

  @spec parse_errors(Ecto.Changeset.t) ::
    {:ok, Ecto.Changeset.t}
    | {:error, :file_exists | Ecto.Changeset.t}
  defp parse_errors(changeset) do
    # FIXME: use a proper error parsing method
    case changeset do
      {:ok, file} ->
        {:ok, file}
      {:error, changeset} ->
        if Keyword.get(changeset.errors, :file_path) do
          {:error, :file_exists}
        else
          {:error, changeset}
        end
    end
  end
end