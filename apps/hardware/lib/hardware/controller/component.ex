defmodule HELM.Hardware.Controller.Component do
  import Ecto.Query

  alias HELF.Broker
  alias HELM.Hardware.Repo
  alias HELM.Hardware.Model.Component, as: MdlComp

  def create(params) do
    MdlComp.create_changeset(params)
    |> Repo.insert()
  end

  def find(component_id) do
    case Repo.get_by(MdlComp, component_id: component_id) do
      nil -> {:error, :notfound}
      res -> {:ok, res}
    end
  end

  def delete(component_id) do
    MdlComp
    |> where([s], s.component_id == ^component_id)
    |> Repo.delete_all()

    :ok
  end
end