defmodule Helix.Software.Controller.File do

  alias Helix.Software.Repo
  alias Helix.Software.Model.File
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

  @spec delete(HELL.PK.t) :: no_return
  def delete(file_id) do
    File
    |> where([f], f.file_id == ^file_id)
    |> Repo.delete_all()

    :ok
  end
end