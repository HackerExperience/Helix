defmodule HELM.Software.Controller.File do
  import Ecto.Query

  alias HELM.Software.Model.Repo
  alias HELM.Software.Model.File, as: MdlFile

  def create(file) do
    file
    |> MdlFile.create_changeset()
    |> Repo.insert()
  end

  def find(file_id) do
    case Repo.get_by(MdlFile, file_id: file_id) do
      nil -> {:error, :notfound}
      changeset -> {:ok, changeset}
    end
  end

  def update(file_id, params) do
    with {:ok, file} <- find(file_id) do
      file
      |> MdlFile.update_changeset(params)
      |> Repo.update()
    end
  end

  def delete(file_id) do
    MdlFile
    |> where([s], s.file_id == ^file_id)
    |> Repo.delete_all()

    :ok
  end
end