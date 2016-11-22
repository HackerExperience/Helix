defmodule HELM.Software.Controller.Module do

  alias HELM.Software.Repo
  alias HELM.Software.Model.Module, as: MdlModule
  import Ecto.Query, only: [where: 3]

  @spec create(MdlModule.creation_params) :: {:ok, MdlModule.t} | {:error, Ecto.Changeset.t}
  def create(params) do
    params
    |> MdlModule.create_changeset()
    |> Repo.insert()
  end

  @spec find(HELL.PK.t, String.t) :: {:ok, MdlModule.t} | {:error, :notfound}
  def find(file_id, role) do
    case Repo.get_by(MdlModule, module_role_id: role, file_id: file_id) do
      nil ->
        {:error, :notfound}
      res ->
        {:ok, res}
    end
  end

  @spec update(HELL.PK.t, String.t, MdlModule.update_fields) :: {:ok, MdlModule.t} | {:error, Ecto.Changeset.t}
  def update(file_id, module_role, params) do
    with {:ok, module} <- find(file_id, module_role) do
      module
      |> MdlModule.update_changeset(params)
      |> Repo.update()
    end
  end

  # REVIEW: I don't think this function is of any use. A file _should always_
  #   have all modules linked (even if at "0" version). Meanwhile, a "cascade
  #   delete" function could be useful
  @spec delete(HELL.PK.t, String.t) :: no_return
  def delete(file_id, module_role) do
    MdlModule
    |> where([m], m.module_role_id == ^module_role)
    |> where([m], m.file_id == ^file_id)
    |> Repo.delete_all()

    :ok
  end
end