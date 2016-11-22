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
    case Repo.get_by(MdlModule, module_role: role, file_id: file_id) do
      nil ->
        {:error, :notfound}
      res ->
        {:ok, res}
    end
  end

  # REVIEW: I don't think this function is of any use. A file _should always_
  #   have all modules linked (even if at "0" version). Meanwhile, a "cascade
  #   delete" function could be useful
  @spec delete(HELL.PK.t, String.t) :: no_return
  def delete(file_id, role) do
    MdlModule
    |> where([m], m.module_role == ^role)
    |> where([m], m.file_id == ^file_id)
    |> Repo.delete_all()

    :ok
  end
end