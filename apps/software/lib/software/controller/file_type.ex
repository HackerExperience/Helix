defmodule HELM.Software.Controller.FileType do

  import Ecto.Query, only: [where: 3]

  alias HELM.Software.Repo
  alias HELM.Software.Model.FileType, as: MdlFileType

  def create(params) do
    params
    |> MdlFileType.create_changeset()
    |> Repo.insert()
  end

  def find(file_type) do
    case Repo.get_by(MdlFileType, file_type: file_type) do
      nil -> {:error, :notfound}
      res -> {:ok, res}
    end
  end

  def delete(file_type) do
    MdlFileType
    |> where([s], s.file_type == ^file_type)
    |> Repo.delete_all()

    :ok
  end
end