defmodule HELM.Software.Controller.File do

  alias HELM.Software.Repo
  alias HELM.Software.Model.File, as: MdlFile

  import Ecto.Query, only: [where: 3]

  @spec create(%{}) :: {:ok, MdlFile.t} | {:error, Ecto.Changeset.t}
  def create(params) do
    params
    |> MdlFile.create_changeset()
    |> Repo.insert()
  end

  @spec find(HELL.PK.t) :: {:ok, MdlFile.t} | {:error, :notfound}
  def find(file_id) do
    case Repo.get_by(MdlFile, file_id: file_id) do
      nil ->
        {:error, :notfound}
      file ->
        {:ok, file}
    end
  end

  @spec update(HELL.PK.t, %{}) :: {:ok, MdlFile.t} | {:error, Ecto.Changeset.t} | {:error, :notfound}
  def update(file_id, params) do
    with {:ok, file} <- find(file_id) do
      file
      |> MdlFile.update_changeset(params)
      |> Repo.update()
    end
  end

  @spec delete(HELL.PK.t) :: no_return
  def delete(file_id) do
    MdlFile
    |> where([f], f.file_id == ^file_id)
    |> Repo.delete_all()

    :ok
  end
end