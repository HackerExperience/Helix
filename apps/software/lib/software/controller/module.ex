defmodule HELM.Software.Controller.Module do
  import Ecto.Query

  alias HELM.Software.Model.Repo
  alias HELM.Software.Model.Module, as: MdlModule

  def create(params) do
    params
    |> MdlModule.create_changeset()
    |> Repo.insert()
  end

  def find(role, file_id) do
    case Repo.get_by(MdlModule, module_role: role, file_id: file_id) do
      nil -> {:error, :notfound}
      res -> {:ok, res}
    end
  end

  def delete(module_role, file_id) do
    MdlModule
    |> where([s], s.module_role == ^module_role and s.file_id == ^file_id)
    |> Repo.delete_all()

    :ok
  end
end