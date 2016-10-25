defmodule HELM.Hardware.Controller.ComponentTypes do
  import Ecto.Query

  alias HELF.{Broker, Error}
  alias HELM.Hardware.Model.Repo
  alias HELM.Hardware.Model.ComponentTypes, as: MdlCompTypes

  def create(component_type) do
    MdlCompTypes.create_changeset(%{component_type: component_type})
    |> do_create
  end

  def find(component_type) do
    case Repo.get_by(MdlCompTypes, component_type: component_type) do
      nil -> {:error, :notfound}
      res -> {:ok, res}
    end
  end

  def all do
    MdlCompTypes
    |> select([t], t.component_type)
    |> Repo.all
  end

  def delete(component_type) do
    with {:ok, comp_type} <- find(component_type),
         {:ok, _} <- Repo.delete(comp_type) do
      :ok
    else
      {:error, :notfound} -> :ok
    end
  end

  defp do_create(changeset) do
    case Repo.insert(changeset) do
      {:ok, schema} ->
        Broker.cast("event:component:type:created", changeset.changes.component_type)
        {:ok, schema}
      {:error, changeset} ->
        {:error, changeset}
    end
  end
end