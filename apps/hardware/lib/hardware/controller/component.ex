defmodule HELM.Hardware.Controller.Component do

  alias HELM.Hardware.Repo
  alias HELM.Hardware.Model.Component, as: MdlComp
  import Ecto.Query, only: [where: 3]

  @spec create(MdlComp.creation_params) :: {:ok, MdlComp.t} | {:error, Ecto.Changeset.t}
  def create(params) do
    params
    |> MdlComp.create_changeset()
    |> Repo.insert()
  end

  @spec find(HELL.PK.t) :: {:ok, MdlComp.t} | {:error, :notfound}
  def find(component_id) do
    case Repo.get_by(MdlComp, component_id: component_id) do
      nil ->
        {:error, :notfound}
      res ->
        {:ok, res}
    end
  end

  @spec update(HELL.PK.t, MdlComp.update_fields) :: {:ok, MdlComp.t} | {:error, :notfound | Ecto.Changeset.t}
  def update(component_id, params) do
    with {:ok, comp} <- find(component_id) do
      comp
      |> MdlComp.update_changeset(params)
      |> Repo.update()
    end
  end

  @spec delete(HELL.PK.t) :: no_return
  def delete(component_id) do
    MdlComp
    |> where([s], s.component_id == ^component_id)
    |> Repo.delete_all()

    :ok
  end
end