defmodule HELM.Software.Controller.ModuleRoles do
  import Ecto.Query

  alias HELM.Software.Model.Repo
  alias HELM.Software.Model.ModuleRoles, as: MdlModuleRoles

  def create(role, type) do
    %{module_role: role,
      file_type: type}
    |> MdlModuleRoles.create_changeset()
    |> Repo.insert()
  end

  def find(role, type) do
    case Repo.get_by(MdlModuleRoles, module_role: role, file_type: type) do
      nil -> {:error, :notfound}
      res -> {:ok, res}
    end
  end

  def delete(role, type) do
    case find(role, type) do
      {:ok, file} -> Repo.delete(file)
      error -> error
    end
  end
end
