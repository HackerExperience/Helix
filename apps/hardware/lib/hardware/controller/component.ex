defmodule HELM.Hardware.Controller.Component do
  import Ecto.Query

  alias HELF.Broker
  alias HELM.Hardware.Repo
  alias HELM.Hardware.Model.Component, as: MdlComp

  def create(params) do
    MdlComp.create_changeset(params)
    |> do_create()
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