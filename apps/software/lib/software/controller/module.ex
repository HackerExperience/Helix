defmodule Helix.Software.Controller.Module do

  alias Helix.Software.Model.Module
  alias Helix.Software.Repo

  import Ecto.Query, only: [where: 3]

  @spec create(Module.creation_params) :: {:ok, Module.t} | {:error, Ecto.Changeset.t}
  def create(params) do
    params
    |> Module.create_changeset()
    |> Repo.insert()
  end

  @spec find(HELL.PK.t, String.t) :: {:ok, Module.t} | {:error, :notfound}
  def find(file_id, role) do
    case Repo.get_by(Module, module_role_id: role, file_id: file_id) do
      nil ->
        {:error, :notfound}
      res ->
        {:ok, res}
    end
  end

  @spec update(HELL.PK.t, String.t, Module.update_fields) :: {:ok, Module.t} | {:error, Ecto.Changeset.t}
  def update(file_id, module_role, params) do
    with {:ok, module} <- find(file_id, module_role) do
      module
      |> Module.update_changeset(params)
      |> Repo.update()
    end
  end

  # REVIEW: I don't think this function is of any use. A file _should always_
  #   have all modules linked (even if at "0" version). Meanwhile, a "cascade
  #   delete" function could be useful
  @spec delete(HELL.PK.t, String.t) :: no_return
  def delete(file_id, module_role) do
    Module
    |> where([m], m.module_role_id == ^module_role)
    |> where([m], m.file_id == ^file_id)
    |> Repo.delete_all()

    :ok
  end
end