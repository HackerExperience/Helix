defmodule HELM.Software.Module.Role.Controller do
  import Ecto.Query

  alias HELM.Software.Repo
  alias HELM.Software.Module.Role.Schema, as: SoftModuleRoleSchema

  def create(role, type) do
    %{module_role: role,
      file_type: type}
    |> SoftModuleRoleSchema.create_changeset
    |> do_create
  end

  def find(role, type) do
    case Repo.get_by(SoftModuleRoleSchema, module_role: role, file_type: type) do
      nil -> {:error, "Role not found."}
      res -> {:ok, res}
    end
  end

  def delete(role, type) do
    case find(role, type) do
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
