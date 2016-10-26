defmodule HELM.Hardware.Controller.Components do
  import Ecto.Query

  alias HELF.Broker
  alias HELM.Hardware.Model.Repo
  alias HELM.Hardware.Model.Components, as: MdlComps

  def create(params) do
    MdlComps.create_changeset(params)
    |> do_create()
  end

  def find(component_id) do
    case Repo.get_by(MdlComps, component_id: component_id) do
      nil -> {:error, :notfound}
      res -> {:ok, res}
    end
  end

  def delete(component_id) do
    MdlComps
    |> where([s], s.component_id == ^component_id)
    |> Repo.delete_all()

    :ok
  end

  defp do_create(changeset) do
    case Repo.insert(changeset) do
      {:ok, schema} ->
        Broker.cast("event:component:created", schema.component_id)
        {:ok, schema}
      {:error, changeset} ->
        {:error, changeset}
    end
  end
end