defmodule HELM.Hardware.Component.Spec.Controller do
  import Ecto.Query

  alias HELF.{Broker, Error}
  alias HELM.Hardware
  alias HELM.Hardware.Component

  def new_spec(component_type, spec) do
    %{component_type: component_type, spec: spec}
    |> Component.Spec.Schema.create_changeset
    |> do_new_spec
  end

  def do_new_spec(changeset) do
    case Hardware.Repo.insert(changeset) do
      {:ok, schema} ->
        Broker.cast("event:component:spec:created", changeset.changes.spec_id)
        {:ok, schema}
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def find_spec(spec_id) do
    case Hardware.Repo.get_by(Component.Spec.Schema, spec_id: spec_id) do
      nil -> {:error, "Component.Spec not found."}
      res -> {:ok, res}
    end
  end

  def remove_spec(spec_id) do
    case find_spec(spec_id) do
      {:ok, spec} -> do_remove_spec(spec)
      error -> error
    end
  end

  defp do_remove_spec(component_spec) do
    case Hardware.Repo.delete(component_spec) do
      {:ok, result} -> {:ok, result}
      {:error, msg} -> {:error, msg}
    end
  end
end
