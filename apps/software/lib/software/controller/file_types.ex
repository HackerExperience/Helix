defmodule HELM.Software.File.Type.Controller do
  import Ecto.Query

  alias HELM.Software.Repo
  alias HELM.Software.File.Type.Schema, as: FileTypeSchema

  def create(file_type, extension) do
    %{file_type: file_type, extension: extension}
    |> FileTypeSchema.create_changeset()
    |> Repo.insert()
  end

  def find(file_type) do
    case Repo.get_by(FileTypeSchema, file_type: file_type) do
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
