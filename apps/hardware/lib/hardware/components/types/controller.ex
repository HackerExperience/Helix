defmodule HELM.Hardware.Component.Type.Controller do
  import Ecto.Query

  alias HELF.{Broker, Error}
  alias HELM.Hardware
  alias HELM.Hardware.Component

  def new(component_type) do
    Component.Type.Schema.create_changeset(%{component_type: component_type})
    |> do_new_type
  end

  defp do_new_type(changeset) do
    case Hardware.Repo.insert(changeset) do
      {:ok, schema} ->
        Broker.cast("event:component:type:created", changeset.changes.component_type)
        {:ok, schema}
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def find(component_type) do
    case Hardware.Repo.get_by(Component.Type.Schema, component_type: component_type) do
      nil -> {:error, "Component.Type not found."}
      res -> {:ok, res}
    end
  end

  def remove(component_type) do
    case Hardware.Repo.delete(component_type) do
      {:ok, result} -> {:ok, result}
      {:error, msg} -> {:error, msg}
    end
  end
end
