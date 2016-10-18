defmodule HELM.Software.File.Controller do
  import Ecto.Query

  alias HELM.Software.Repo
  alias HELM.Software.File.Schema, as: FileSchema

  def create(storage, path, name, type, size) do
    %{storage_id: storage,
      file_path: path,
      file_name: name,
      file_type: type,
      file_size: size}
    |> FileSchema.create_changeset()
    |> do_create()
  end

  def find(file_id) do
    case Repo.get_by(FileSchema, file_id: file_id) do
      nil -> {:error, :notfound}
      changeset -> {:ok, changeset}
    end
  end

  def delete(file_id) do
    case find(file_id) do
      {:ok, file} -> do_delete(file)
      error -> error
    end
  end

  defp do_create(changeset) do
    Repo.insert(changeset)
  end

  defp do_delete(changeset) do
    Repo.delete(changeset)
  end
end
