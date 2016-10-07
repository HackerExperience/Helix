defmodule HELM.Hardware.Component.Controller do
  import Ecto.Query

  alias HELF.{Broker, Error}
  alias HELM.Hardware
  alias HELM.Hardware.Component

  def new_component(component_type, spec_id) do
    %{component_type: component_type, spec_id: spec_id}
    |> Component.Schema.create_changeset
    |> do_new_component
  end

  defp do_new_component(changeset) do
    case Hardware.Repo.insert(changeset) do
      {:ok, schema} ->
        Broker.cast("event:component:created", changeset.changes.component_id)
        {:ok, schema}
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def find_component(component_id) do
    case Hardware.Repo.get_by(Component.Schema, component_id: component_id) do
      nil -> {:error, "Component not found."}
      res -> {:ok, res}
    end
  end

  def remove_component(component_id) do
    case find_component(component_id) do
      {:ok, component} -> do_remove_component(component)
      error -> error
    end
  end

  defp do_remove_component(component) do
    case Hardware.Repo.delete(component) do
      {:ok, result} -> {:ok, result}
      {:error, msg} -> {:error, msg}
    end
  end
end
