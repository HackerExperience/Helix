defmodule HELM.Software.File.Type.Controller do
  import Ecto.Query

  alias HELM.Software.Repo
  alias HELM.Software.File.Type.Schema, as: SoftFileTypeSchema

  def create(file_type, extension) do
    %{file_type: file_type, extension: extension}
    |> SoftFileTypeSchema.create_changeset
    |> do_create
  end

  def find(file_type) do
    case Repo.get_by(SoftFileTypeSchema, file_type: file_type) do
      nil -> {:error, "File.Type not found."}
      res -> {:ok, res}
    end
  end

  def delete(file_type) do
    case find(file_type) do
      {:ok, drive} -> do_delete(drive)
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
