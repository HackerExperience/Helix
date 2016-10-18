defmodule HELM.Software.File.Controller do
  import Ecto.Query

  alias HELM.Software.Repo
  alias HELM.Software.File.Schema, as: SoftFileSchema

  def create(storage, path, name, type, size) do
    %{storage_id: storage,
      file_path: path,
      file_name: name,
      file_type: type,
      file_size: size}
    |> SoftFileSchema.create_changeset
    |> do_create
  end

  def find(file_id) do
    case Repo.get_by(SoftFileSchema, file_id: file_id) do
      nil -> {:error, "File not found."}
      res -> {:ok, res}
    end
  end

  def delete(file_id) do
    case find(file_id) do
      {:ok, file} -> do_delete(file)
      error -> error
    end
  end

  defp do_create(changeset) do
    case Repo.insert(changeset) do
      {:ok, schema} ->
        {:ok, schema}
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp do_delete(changeset) do
    case Repo.delete(changeset) do
      {:ok, result} -> {:ok, result}
      {:error, msg} -> {:error, msg}
    end
  end
end
