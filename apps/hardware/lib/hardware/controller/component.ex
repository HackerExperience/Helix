defmodule Helix.Hardware.Controller.Component do

  alias Helix.Hardware.Repo
  alias Helix.Hardware.Model.Component, as: MdlComp
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

  @spec delete(HELL.PK.t) :: no_return
  def delete(component_id) do
    MdlComp
    |> where([s], s.component_id == ^component_id)
    |> Repo.delete_all()

    :ok
  end
end