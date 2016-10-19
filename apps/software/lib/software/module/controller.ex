defmodule HELM.Software.Module.Controller do
  import Ecto.Query

  alias HELM.Software.Repo
  alias HELM.Software.Module.Schema, as: ModuleSchema

  def create(role, file_id, version) do
    %{module_role: role,
      file_id: file_id,
      module_version: version}
    |> ModuleSchema.create_changeset()
    |> Repo.insert()
  end

  def find(role, file_id) do
    case Repo.get_by(ModuleSchema, module_role: role, file_id: file_id) do
      nil -> {:error, :notfound}
      res -> {:ok, res}
    end
  end

  def delete(role, file_id) do
    case find(role, file_id) do
      {:ok, file} -> Repo.delete(file)
      error -> error
    end
  end
end
