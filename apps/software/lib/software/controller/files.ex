defmodule HELM.Software.Controller.Files do
  import Ecto.Query

  alias HELM.Software.Model.Repo
  alias HELM.Software.Model.Files, as: MdlFiles

  def create(storage, path, name, type, size) do
    %{storage_id: storage,
      file_path: path,
      file_name: name,
      file_type: type,
      file_size: size}
    |> MdlFiles.create_changeset()
    |> Repo.insert()
  end

  def find(file_id) do
    case Repo.get_by(MdlFiles, file_id: file_id) do
      nil -> {:error, :notfound}
      changeset -> {:ok, changeset}
    end
  end

  def update(file_id, params) do
    case find(file_id) do
      {:ok, file} ->
        file
        |> MdlFiles.update_changeset(params)
        |> Repo.update()
      error -> error
    end
  end

  def delete(file_id) do
    case find(file_id) do
      {:ok, file} -> Repo.delete(file)
      error -> error
    end
  end
end
