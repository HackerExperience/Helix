defmodule HELM.Hardware.Component.Controller do
  import Ecto.Query

  alias HELF.{Broker, Error}
  alias HELM.Hardware.Repo
  alias HELM.Hardware.Component.Schema, as: CompSchema

  def create(component_type, spec_id) do
    %{component_type: component_type, spec_id: spec_id}
    |> CompSchema.create_changeset
    |> do_create
  end

  def find(component_id) do
    case Repo.get_by(CompSchema, component_id: component_id) do
      nil -> {:error, "Component not found."}
      res -> {:ok, res}
    end
  end

  def delete(component_id) do
    case find(component_id) do
      {:ok, component} -> do_delete(component)
      error -> error
    end
  end

  defp do_create(changeset) do
    case Repo.insert(changeset) do
      {:ok, schema} ->
        Broker.cast("event:component:created", changeset.changes.component_id)
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
