defmodule HELM.Software.Controller.ModuleRole do
  import Ecto.Query

  alias HELM.Software.Model.Repo
  alias HELM.Software.Model.ModuleRole, as: MdlModuleRole

  def create(params) do
    params
    |> MdlModuleRole.create_changeset()
    |> Repo.insert()
  end

  def find(role, type) do
    case Repo.get_by(MdlModuleRole, module_role: role, file_type: type) do
      nil -> {:error, :notfound}
      res -> {:ok, res}
    end
  end

  def delete(module_role, file_type) do
    MdlModuleRole
    |> where([s], s.module_role == ^module_role and s.file_type == ^file_type)
    |> Repo.delete_all()

    :ok
  end
end