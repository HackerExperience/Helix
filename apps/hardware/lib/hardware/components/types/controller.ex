defmodule HELM.Hardware.Component.Type.Controller do
  import Ecto.Query

  alias HELF.{Broker, Error}
  alias HELM.Hardware.Repo
  alias HELM.Hardware.Component.Type.Schema, as: CompTypeSchema

  def create(component_type) do
    CompTypeSchema.create_changeset(%{component_type: component_type})
    |> do_create
  end

  def find(component_type) do
    case Repo.get_by(CompTypeSchema, component_type: component_type) do
      nil -> {:error, "Component.Type not found."}
      res -> {:ok, res}
    end
  end

  def delete(component_type) do
    case find(component_type) do
      {:ok, comp_type} -> do_delete(comp_type)
      error -> error
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

  defp do_delete(component) do
    case Repo.delete(component) do
      {:ok, result} -> {:ok, result}
      {:error, msg} -> {:error, msg}
    end
  end
end
