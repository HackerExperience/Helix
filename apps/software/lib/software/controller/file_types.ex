defmodule HELM.Software.Controller.FileType do
  import Ecto.Query

  alias HELM.Software.Model.Repo
  alias HELM.Software.Model.FileType, as: MdlFileType

  def create(file_type, extension) do
    %{file_type: file_type, extension: extension}
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
    case find(file_type) do
      {:ok, drive} -> Repo.delete(drive)
      error -> error
    end
  end
end
