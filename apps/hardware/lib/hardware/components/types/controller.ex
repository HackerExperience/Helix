defmodule HELM.Hardware.Component.Type.Controller do
  import Ecto.Query

  alias HELF.{Broker, Error}
  alias HELM.Hardware.Repo
  alias HELM.Hardware.Component.Type.Schema, as: CompTypeSchema

  def new_type(component_type) do
    CompTypeSchema.create_changeset(%{component_type: component_type})
    |> do_new_type
  end

  defp do_new_type(changeset) do
    case Repo.insert(changeset) do
      {:ok, schema} ->
        Broker.cast("event:component:type:created", changeset.changes.component_type)
        {:ok, schema}
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def find_type(component_type) do
    case Repo.get_by(CompTypeSchema, component_type: component_type) do
      nil -> {:error, "Component.Type not found."}
      res -> {:ok, res}
    end
  end

  def remove_type(component_type) do
    case find_type(component_type) do
      {:ok, comp_type} -> do_remove_type(comp_type)
      error -> error
    end
  end

  defp do_remove_type(component) do
    case Repo.delete(component) do
      {:ok, result} -> {:ok, result}
      {:error, msg} -> {:error, msg}
    end
  end
end