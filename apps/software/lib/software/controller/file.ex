defmodule Helix.Software.Controller.File do

  alias Helix.Software.Model.File
  alias Helix.Software.Repo

  import Ecto.Query, only: [where: 3]

  @spec create(File.creation_params) :: {:ok, File.t} | {:error, Ecto.Changeset.t}
  def create(params) do
    params
    |> File.create_changeset()
    |> Repo.insert()
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

  @spec update(HELL.PK.t, File.update_params) :: {:ok, File.t} | {:error, :notfound | Ecto.Changeset.t}
  def update(file_id, params) do
    with {:ok, file} <- find(file_id) do
      file
      |> File.update_changeset(params)
      |> Repo.update()
    end
  end

  @spec move(File.t, String.t) :: {:ok, File.t} | {:error, Ecto.Changeset.t}
  def move(file, file_path) do
    file
    |> File.update_changeset(%{file_path: file_path})
    |> Repo.update()
  end

  @spec rename(File.t, String.t) :: {:ok, File.t} | {:error, Ecto.Changeset.t}
  def rename(file, file_name) do
    file
    |> File.update_changeset(%{name: file_name})
    |> Repo.update()
  end

  @spec delete(HELL.PK.t) :: no_return
  def delete(file_id) do
    File
    |> where([f], f.file_id == ^file_id)
    |> Repo.delete_all()

    :ok
  end
end